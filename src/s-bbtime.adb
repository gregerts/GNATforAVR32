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

   type Stack_Index is new Interrupts.Interrupt_Level;

   type Clock_Stack is array (Stack_Index) of Clock_Id;
   pragma Suppress_Initialization (Clock_Stack);

   type Pool_Index is range 0 .. SBP.Interrupt_Clocks + 1;
   for Pool_Index'Size use 8;

   -----------------------
   -- Local definitions --
   -----------------------

   Max_Compare : constant := Word'Last / 2 - 1;
   --  Maximal value set to COMPARE register

   Stack : Clock_Stack;
   --  Stack of timers

   Top : Stack_Index;
   --  Index of stack top

   ETC : Clock_Id;
   --  The currently running execution time clock = Stack (Top)

   Pool : array (Pool_Index) of aliased Clock_Descriptor;
   --  Pool of clocks

   Last : Pool_Index := 1;
   --  Pointing to last allocated clock in pool

   Lookup : array (Interrupt_ID) of Pool_Index;
   --  Array for translating interrupt IDs to interrupt clock index

   RTC : constant Clock_Id := Pool (0)'Access;
   --  The real-time clock

   Idle : constant Clock_Id := Pool (1)'Access;
   --  Clock of the pseudo idle thread

   Sentinel : aliased Alarm_Descriptor;
   --  Always the last alarm in the queue of every clock

   -----------------------
   -- Local subprograms --
   -----------------------

   function Active (Clock : Clock_Id) return Boolean;
   pragma Inline_Always (Active);
   --  Returns true when the given clock is active (running)

   procedure Alarm_Wrapper (Clock : Clock_Id);
   --  Calls all expired alarm handlers for the given clock

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID);
   --  Handler for the COMPARE interrupt

   procedure Context_Switch (First : Thread_Id);
   pragma Export (Asm, Context_Switch, "timer_context_switch");
   --  Changes time context to first thread

   function Defer_Updates return Boolean;
   pragma Inline_Always (Defer_Updates);
   --  Returns true if COMPARE updates are to be deferred

   procedure Initialize_Clock
     (Clock    : Clock_Id;
      Capacity : Natural);
   --  Initializes the given clock

   function Remaining (Clock : Clock_Id) return Time_Span;
   pragma Inline_Always (Remaining);
   --  Returns time remaining until first alarm of clock

   procedure Swap_ETC (Clock : Clock_Id);
   --  Swaps ETC to the given clock

   procedure Update_Compare;
   --  Update COMPARE as timeout of active clock has changed

   ------------
   -- Active --
   ------------

   function Active (Clock : Clock_Id) return Boolean is
   begin
      return Clock = RTC or Clock = ETC;
   end Active;

   -------------------
   -- Alarm_Wrapper --
   -------------------

   procedure Alarm_Wrapper (Clock : Clock_Id) is
      Alarm : Alarm_Id;
      Now   : Time;

   begin

      pragma Assert (Clock /= ETC);

      if Clock = RTC then
         Now := Clock.Base_Time + Time (CPU.Get_Count);
      else
         Now := Clock.Base_Time;
      end if;

      loop

         Alarm := Clock.First_Alarm;

         exit when Alarm.Timeout > Now;

         Clock.First_Alarm := Alarm.Next;
         Alarm.Next := null;

         Alarm.Handler (Alarm.Data);

      end loop;

   end Alarm_Wrapper;

   ------------
   -- Cancel --
   ------------

   procedure Cancel (Alarm : Alarm_Id) is
      Clock : constant Clock_Id := Alarm.Clock;
      Aux : Alarm_Id;

   begin

      --  Nothing to be done if the alarm is not set

      if Alarm.Next = null then
         return;
      end if;

      --  Check if Alarm is first in queue

      if Alarm = Clock.First_Alarm then

         Clock.First_Alarm := Alarm.Next;

         if Active (Clock) then
            Update_Compare;
         end if;

      else

         Aux := Clock.First_Alarm;

         while Aux.Next /= Alarm loop
            Aux := Aux.Next;
         end loop;

         Aux.Next := Alarm.Next;

      end if;

      Alarm.Next := null;

   end Cancel;

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

      --  Call alarm handlers for interrupted execution time clock

      Alarm_Wrapper (Stack (Top - 1));

      --  Call alarm handlers for real-time clock

      Alarm_Wrapper (RTC);

   end Compare_Handler;

   --------------------
   -- Context_Switch --
   --------------------

   procedure Context_Switch (First : Thread_Id) is
   begin
      pragma Assert (Top = 0);

      Stack (0) := First.Active_Clock;
      Swap_ETC (First.Active_Clock);

   end Context_Switch;

   -------------------
   -- Defer_Updates --
   -------------------

   function Defer_Updates return Boolean is
   begin
      return Threads.Get_Priority (Threads.Thread_Self) = Any_Priority'Last;
   end Defer_Updates;

   ----------------
   -- Enter_Idle --
   ----------------

   procedure Enter_Idle (Id : Thread_Id) is
   begin
      pragma Assert (Top = 0);
      pragma Assert (ETC = Id.Active_Clock);
      pragma Assert (Id.Active_Clock = Id.Clock'Access);

      Id.Active_Clock := Idle;
      Stack (0) := Idle;

      Swap_ETC (Idle);

   end Enter_Idle;

   ---------------------
   -- Enter_Interrupt --
   ---------------------

   procedure Enter_Interrupt (Id : Interrupt_ID) is
      Clock : constant Clock_Id := Pool (Lookup (Id))'Access;
   begin
      pragma Assert (Top < Stack'Last);
      pragma Assert (Lookup (Id) > 0);

      Top         := Top + 1;
      Stack (Top) := Clock;

      Swap_ETC (Clock);

   end Enter_Interrupt;

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

         Alarm.all := (Timeout => Time'Last,
                       Clock   => Clock,
                       Handler => Handler,
                       Data    => Data,
                       Next    => null);

         Success := True;

      else
         Success := False;
      end if;

   end Initialize_Alarm;

   ----------------------
   -- Initialize_Clock --
   ----------------------

   procedure Initialize_Clock
     (Clock    : Clock_Id;
      Capacity : Natural)
   is
   begin
      Clock.all := (Base_Time   => Time'First,
                    Capacity    => Capacity,
                    First_Alarm => Sentinel'Access);
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

   -----------------------
   -- Initialize_Timers --
   -----------------------

   procedure Initialize_Timers (Environment_Thread : Thread_Id) is
      Count : constant Word := CPU.Swap_Count (Max_Compare);
   begin
      --  Initialize sentinel alarm

      Sentinel.Timeout := Time'Last;

      --  Initialize execution time clock of environment thread

      Initialize_Thread_Clock (Environment_Thread);
      Environment_Thread.Clock.Base_Time := Time (Count);

      --  Initialize execution time clock for idling, no alarms

      Initialize_Clock (Idle, 0);

      --  Initialize real-time clock, no limit on alarms

      Initialize_Clock (RTC, Natural'Last);
      RTC.Base_Time := Time (Count);

      --  Install compare handler

      Interrupts.Attach_Handler (Compare_Handler'Access, Peripherals.COMPARE);

      --  Activate clock of environment thread

      ETC := Environment_Thread.Clock'Access;
      Stack (0) := ETC;

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
      Clock : constant Clock_Id := Id.Clock'Access;
   begin
      pragma Assert (Top = 0);
      pragma Assert (ETC = Idle);
      pragma Assert (Id.Active_Clock = Idle);

      Id.Active_Clock := Clock;
      Stack (0) := Clock;

      Swap_ETC (Clock);

   end Leave_Idle;

   ---------------------
   -- Leave_Interrupt --
   ---------------------

   procedure Leave_Interrupt is
   begin
      pragma Assert (Top > 0);

      Stack (Top) := null;
      Top := Top - 1;

      Swap_ETC (Stack (Top));

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

   ---------------
   -- Remaining --
   ---------------

   function Remaining (Clock : Clock_Id) return Time_Span is
      Alarm : constant Alarm_Id := Clock.First_Alarm;
   begin
      return Time_Span (Alarm.Timeout) - Time_Span (Clock.Base_Time);
   end Remaining;

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
      pragma Assert (Timeout < Time'Last);

      --  Remove alarm from queue if necessary

      Cancel (Alarm);

      --  Set alarm timeout

      Alarm.Timeout := Timeout;

      --  Check if alarm is to be first in queue

      if Timeout < Clock.First_Alarm.Timeout then

         --  Insert alarm first in queue, update COMPARE in needed

         Alarm.Next := Clock.First_Alarm;
         Clock.First_Alarm := Alarm;

         if Active (Clock) then
            Update_Compare;
         end if;

      else

         --  Find element Aux where Aux.Next.Timeout > Timeout

         Aux := Clock.First_Alarm;

         while Aux.Next.Timeout <= Timeout loop
            Aux := Aux.Next;
         end loop;

         --  Insert after Aux (always before sentinel)

         Alarm.Next := Aux.Next;
         Aux.Next := Alarm;

         pragma Assert (Aux.Timeout <= Timeout);
         pragma Assert (Timeout < Alarm.Next.Timeout);

      end if;

   end Set;

   --------------
   -- Swap_ETC --
   --------------

   procedure Swap_ETC (Clock : Clock_Id) is
      Count : constant Word := CPU.Swap_Count (Max_Compare);
   begin
      pragma Assert (Clock /= null);

      RTC.Base_Time := RTC.Base_Time + Time (Count);
      ETC.Base_Time := ETC.Base_Time + Time (Count);

      ETC := Clock;

      Update_Compare;

   end Swap_ETC;

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
      if Alarm.Next /= null then
         return Alarm.Timeout;
      else
         return Time'First;
      end if;
   end Time_Of_Alarm;

   --------------------
   -- Update_Compare --
   --------------------

   procedure Update_Compare is
      Diff : Time_Span;
   begin

      if not Defer_Updates then

         Diff := Time_Span'Min (Remaining (RTC), Remaining (ETC));

         pragma Assert (Diff >= Time_Span (Integer'First));

         if Diff > Max_Compare then
            CPU.Adjust_Compare (Max_Compare);
         else
            CPU.Adjust_Compare (Word (Integer'Max (Integer (Diff), 0)));
         end if;

      end if;

   end Update_Compare;

end System.BB.Time;
