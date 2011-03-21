------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                         S Y S T E M . B B . T I M E                      --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
--                     Copyright (C) 2003-2007, AdaCore                     --
--             Copyright (C) 2008-2011, Kristoffer N. Gregertsen            --
--                                                                          --
-- GNARL is free software; you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. GNARL is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
--
--
--
--
--
--
--
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by Ada Core Technologies, Inc.     --
--                                                                          --
-- The porting of GNARL to bare board  targets was initially  developed  by --
-- the Real-Time Systems Group at the Technical University of Madrid.       --
--                                                                          --
------------------------------------------------------------------------------

pragma Restrictions (No_Elaboration_Code);

with System.BB.CPU_Primitives;
with System.BB.Parameters;
with System.BB.Threads;

package body System.BB.Time is

   package CPU renames System.BB.CPU_Primitives;
   package SBP renames System.BB.Parameters;

   use type CPU.Word;

   subtype Word is CPU.Word;

   type Pool_Index is range 0 .. SBP.Interrupt_Clocks + 1;
   for Pool_Index'Size use 8;

   type Stack_Index is new Interrupts.Interrupt_Level;

   type Clock_Stack is array (Stack_Index) of Clock_Id;
   pragma Suppress_Initialization (Clock_Stack);

   -----------------------
   -- Local definitions --
   -----------------------

   Max_Compare : constant := Word'Last - 2 ** 16;
   --  Maximal value set to COMPARE register

   Pool : array (Pool_Index) of aliased Clock_Descriptor;
   --  Pool of clocks

   Last : Pool_Index := 1;
   --  Pointing to last allocated clock in pool

   RTC : constant Clock_Id := Pool (0)'Access;
   --  The real-time clock

   Idle : constant Clock_Id := Pool (1)'Access;
   --  Clock of the pseudo idle thread

   Lookup : array (Interrupt_ID) of Pool_Index;
   --  Array for translating interrupt IDs to interrupt clock index

   Stack : Clock_Stack;
   --  Stack of timers

   Top : Stack_Index;
   --  Index of stack top

   Sentinel : aliased Alarm_Descriptor;
   --  Sentinel last in all alarm queues

   Defer_Updates : Boolean := False;
   --  True when updates to COMPARE are to be deferred

   -----------------------
   -- Local subprograms --
   -----------------------

   function Active (Clock : Clock_Id) return Boolean;
   pragma Inline_Always (Active);
   --  Returns true when the given clock is active (running)

   procedure Alarm_Wrapper (Clock : Clock_Id);
   --  Calls all expired alarm handlers for the given clock

   procedure Clear (Alarm : Alarm_Id);
   pragma Inline_Always (Clear);
   --  Clears the given timer

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID);
   --  Handler for the COMPARE interrupt

   procedure Context_Switch (First : Thread_Id);
   pragma Export (Asm, Context_Switch, "timer_context_switch");
   --  Changes time context to first thread

   function Get_Compare (Clock : Clock_Id) return Word;
   --  Computes the COMPARE value for the given clock

   procedure Initialize_Clock
     (Clock    : Clock_Id;
      Capacity : Natural);
   --  Initializes the given clock

   procedure Swap_Clock (A, B : Clock_Id);
   pragma Inline_Always (Swap_Clock);
   --  Swaps execution time clock from A to B

   procedure Update_Compare (Clock : Clock_Id);
   pragma Inline (Update_Compare);
   --  Timeout of Clock.First_Alarm has changed, update COMPARE if needed

   ------------
   -- Active --
   ------------

   function Active (Clock : Clock_Id) return Boolean is
   begin
      return Clock = RTC or else Clock = Stack (Top);
   end Active;

   -------------------
   -- Alarm_Wrapper --
   -------------------

   procedure Alarm_Wrapper (Clock : Clock_Id) is
      Now : constant Time := Time_Of_Clock (Clock);
      Alarm : Alarm_Id := Clock.First_Alarm;

   begin

      while Alarm.Timeout <= Now loop

         Clock.First_Alarm := Alarm.Next;
         Clock.First_Alarm.Prev := null;

         Clear (Alarm);

         Alarm.Handler (Alarm.Data);
         Alarm := Clock.First_Alarm;

      end loop;

   end Alarm_Wrapper;

   ------------
   -- Cancel --
   ------------

   procedure Cancel (Alarm : Alarm_Id) is
   begin
      pragma Assert (Alarm /= null);

      --  Nothing to be done if the alarm is not set

      if Alarm.Next = null then
         return;
      end if;

      --  Check if Alarm is first in queue

      if Alarm.Prev = null then

         pragma Assert (Alarm.Clock /= null);
         pragma Assert (Alarm.Clock.First_Alarm = Alarm);

         Alarm.Clock.First_Alarm := Alarm.Next;
         Alarm.Next.Prev := null;

         Update_Compare (Alarm.Clock);

      else

         Alarm.Prev.Next := Alarm.Next;
         Alarm.Next.Prev := Alarm.Prev;

      end if;

      Clear (Alarm);

   end Cancel;

   -----------
   -- Clear --
   -----------

   procedure Clear (Alarm : Alarm_Id) is
   begin
      Alarm.Timeout := Time'Last;
      Alarm.Next    := null;
      Alarm.Prev    := null;
   end Clear;

   -----------
   -- Clock --
   -----------

   function Clock (Alarm : Alarm_Id) return Clock_Id is
   begin
      return Alarm.Clock;
   end Clock;

   ---------------------
   -- Compare_Handler --
   ---------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID) is
   begin

      pragma Assert (Id = Peripherals.COMPARE);

      --  Defer updates while within this handler

      Defer_Updates := True;

      --  Call alarm handlers of execution time clock second from top
      --  of stack (no alarms for COMPARE interrupt) and RTC

      Alarm_Wrapper (Stack (Top - 1));
      Alarm_Wrapper (RTC);

      --  COMPARE value will be updated properly when leaving interrupt level

      Defer_Updates := False;

   end Compare_Handler;

   --------------------
   -- Context_Switch --
   --------------------

   procedure Context_Switch (First : Thread_Id) is
      A : constant Clock_Id := Stack (0);
      B : constant Clock_Id := First.Active_Clock;

   begin
      pragma Assert (Top = 0);

      Swap_Clock (A, B);
      Stack (0) := B;

   end Context_Switch;

   ----------------
   -- Enter_Idle --
   ----------------

   procedure Enter_Idle (Id : Thread_Id) is
      A : constant Clock_Id := Id.Active_Clock;
      B : constant Clock_Id := Idle;

   begin
      pragma Assert (Top = 0 and then A = Stack (0));
      pragma Assert (A = Id.Clock'Access);

      Id.Active_Clock := B;
      Stack (0) := B;

      Swap_Clock (A, B);

   end Enter_Idle;

   ---------------------
   -- Enter_Interrupt --
   ---------------------

   procedure Enter_Interrupt (Id : Interrupt_ID) is
      A : constant Clock_Id := Stack (Top);
      B : constant Clock_Id := Pool (Lookup (Id))'Access;

   begin
      pragma Assert (Top < Stack'Last);
      pragma Assert (Lookup (Id) > 0);

      Top         := Top + 1;
      Stack (Top) := B;

      Swap_Clock (A, B);

   end Enter_Interrupt;

   -----------------
   -- Get_Compare --
   -----------------

   function Get_Compare (Clock : Clock_Id) return Word is
      Base  : constant Time     := Clock.Base_Time;
      Alarm : constant Alarm_Id := Clock.First_Alarm;

   begin

      if Alarm.Timeout > (Base + Max_Compare) then
         return Max_Compare;
      elsif Alarm.Timeout > Base then
         return Word (Alarm.Timeout - Base);
      else
         return 1;
      end if;

   end Get_Compare;

   ----------------------
   -- Initialize_Clock --
   ----------------------

   procedure Initialize_Clock
     (Clock    : Clock_Id;
      Capacity : Natural)
   is
   begin
      Clock.all := (Base_Time   => Time'First,
                    First_Alarm => Sentinel'Access,
                    Capacity    => Capacity);
   end Initialize_Clock;

   --------------------------------
   -- Initialize_Interrupt_Clock --
   --------------------------------

   procedure Initialize_Interrupt_Clock (Id : Interrupt_ID) is
   begin
      pragma Assert (Id /= Interrupts.No_Interrupt);
      pragma Assert (Lookup (Id) = 0);
      pragma Assert (Last < Pool_Index'Last);

      --  Allocate next clock in Pool to Id

      Last := Last + 1;
      Lookup (Id) := Last;

      --  Initialize clock, no alarms allowed for highest priority

      if Interrupts.Priority_Of_Interrupt (Id) < Any_Priority'Last then
         Initialize_Clock (Pool (Last)'Access, 1);
      else
         Initialize_Clock (Pool (Last)'Access, 0);
      end if;

   end Initialize_Interrupt_Clock;

   -----------------------------
   -- Initialize_Thread_Clock --
   -----------------------------

   procedure Initialize_Thread_Clock (Id : Thread_Id) is
   begin
      pragma Assert (Id /= null and then Id.Active_Clock = null);

      --  Active clock of thread is thread clock

      Id.Active_Clock := Id.Clock'Access;

      --  Only one alarm for execution time clocks in Ravenscar

      Initialize_Clock (Id.Active_Clock, 1);

   end Initialize_Thread_Clock;

   ----------------------
   -- Initialize_Alarm --
   ----------------------

   procedure Initialize_Alarm
     (Alarm   : Alarm_Id;
      Clock   : Clock_Id;
      Handler : not null Alarm_Handler;
      Data    : System.Address;
      Success : out Boolean)
   is
   begin
      pragma Assert (Alarm /= null);

      if Clock /= null and then Clock.Capacity > 0 then

         Clock.Capacity := Clock.Capacity - 1;

         Alarm.all := (Clock   => Clock,
                       Handler => Handler,
                       Data    => Data,
                       Timeout => Time'Last,
                       Next    => null,
                       Prev    => null);

         Success := True;

      else
         Success := False;
      end if;

   end Initialize_Alarm;

   -----------------------
   -- Initialize_Timers --
   -----------------------

   procedure Initialize_Timers (Environment_Thread : Thread_Id) is
      Count : constant Word := CPU.Swap_Count;
   begin
      --  Initialize execution time clock of environment thread

      Initialize_Thread_Clock (Environment_Thread);
      Environment_Thread.Clock.Base_Time := Time (Count);

      --  Initialize execution time clock for idling, no alarms

      Initialize_Clock (Idle, 0);

      --  Initialize real-time clock, no limit on alarms

      Initialize_Clock (RTC, Natural'Last);
      RTC.Base_Time := Time (Count);

      --  Initialize sentinel alarm

      Sentinel.Timeout := Time'Last;

      --  Install compare handler

      Interrupts.Attach_Handler (Compare_Handler'Access, Peripherals.COMPARE);

      --  Activate clock of environment thread

      Stack (0) := Environment_Thread.Clock'Access;

      --  Set COMPARE to maximal value, no alarms set at this point

      CPU.Adjust_Compare (Max_Compare);

   end Initialize_Timers;

   ---------------------
   -- Interrupt_Clock --
   ---------------------

   function Interrupt_Clock (Id : Interrupt_ID) return Clock_Id is
      I : constant Pool_Index := Lookup (Id);
   begin
      if I > 0 then
         return Pool (I)'Access;
      else
         return null;
      end if;
   end Interrupt_Clock;

   ----------------
   -- Leave_Idle --
   ----------------

   procedure Leave_Idle (Id : Thread_Id) is
      A : constant Clock_Id := Id.Active_Clock;
      B : constant Clock_Id := Id.Clock'Access;

   begin
      pragma Assert (Top = 0 and then A = Stack (0));
      pragma Assert (A = Idle);

      Id.Active_Clock := B;
      Stack (0) := B;

      Swap_Clock (A, B);

   end Leave_Idle;

   ---------------------
   -- Leave_Interrupt --
   ---------------------

   procedure Leave_Interrupt is
      A : constant Clock_Id := Stack (Top);
   begin
      pragma Assert (Top > 0);

      Stack (Top) := null;
      Top := Top - 1;

      Swap_Clock (A, Stack (Top));

   end Leave_Interrupt;

   ---------------------
   -- Monotonic_Clock --
   ---------------------

   function Monotonic_Clock return Time is
   begin
      return Time_Of_Clock (RTC);
   end Monotonic_Clock;

   ---------------------
   -- Real_Time_Clock --
   ---------------------

   function Real_Time_Clock return Clock_Id is
   begin
      return RTC;
   end Real_Time_Clock;

   ---------
   -- Set --
   ---------

   procedure Set
     (Alarm   : Alarm_Id;
      Timeout : Time)
   is
      Clock : constant Clock_Id := Alarm.Clock;
      Aux : Alarm_Id;

   begin

      pragma Assert (Clock /= null);

      --  Set alarm timeout

      Alarm.Timeout := Timeout;

      --  Search for element Aux where Aux.Timeout > Timeout

      Aux := Clock.First_Alarm;

      while Aux.Timeout <= Timeout loop
         Aux := Aux.Next;
      end loop;

      --  Insert before Aux (always before Last_Alarm)

      Alarm.Next := Aux;
      Alarm.Prev := Aux.Prev;
      Aux.Prev := Alarm;

      --  Check if this alarm is to be first in queue

      if Alarm.Prev = null then
         Clock.First_Alarm := Alarm;
         Update_Compare (Clock);
      else
         Alarm.Prev.Next := Alarm;
      end if;

   end Set;

   ----------------
   -- Swap_Clock --
   ----------------

   procedure Swap_Clock (A, B : Clock_Id) is
      Count : constant Word := CPU.Swap_Count;
   begin
      pragma Assert (A /= null);
      pragma Assert (B /= null);
      pragma Assert (A /= B);

      A.Base_Time := A.Base_Time + Time (Count);
      RTC.Base_Time := RTC.Base_Time + Time (Count);

      Update_Compare (B);

   end Swap_Clock;

   -------------------
   -- Time_Of_Clock --
   -------------------

   function Time_Of_Clock (Clock : Clock_Id) return Time is
      Base  : Time;
      Count : Word;

   begin
      pragma Assert (Clock /= null);

      --  If clock is not active return base time

      if not Active (Clock) then
         return Clock.Base_Time;
      end if;

      --  Else the time of clock is sum of base time and count

      loop
         Base  := Clock.Base_Time;
         Count := CPU.Get_Count;
         exit when Base = Clock.Base_Time;
      end loop;

      return Base + Time (Count);

   end Time_Of_Clock;

   ------------------
   -- Thread_Clock --
   ------------------

   function Thread_Clock (Id : Thread_Id) return Clock_Id is
   begin
      return Id.Clock'Access;
   end Thread_Clock;

   -------------------
   -- Time_Of_Alarm --
   -------------------

   function Time_Of_Alarm (Alarm : Alarm_Id) return Time is
   begin
      return Alarm.Timeout;
   end Time_Of_Alarm;

   --------------------
   -- Update_Compare --
   --------------------

   procedure Update_Compare (Clock : Clock_Id) is
      C : Word;
   begin

      if not Defer_Updates and then Active (Clock) then

         C := Get_Compare (Clock);

         if Clock = RTC then
            C := Word'Min (C, Get_Compare (Stack (Top)));
         else
            C := Word'Min (C, Get_Compare (RTC));
         end if;

         CPU.Adjust_Compare (C);

      end if;

   end Update_Compare;

end System.BB.Time;
