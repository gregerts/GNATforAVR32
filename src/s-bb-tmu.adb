------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                          S Y S T E M . B B . T M U                       --
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

with System.BB.Parameters;
with System.BB.Threads;

package body System.BB.TMU is

   use type Interrupts.Interrupt_ID;
   use type Peripherals.TMU_Interval;

   type Stack_Index is new Interrupts.Interrupt_Level;

   type Clock_Stack is array (Stack_Index) of Clock_Id;
   pragma Suppress_Initialization (Clock_Stack);

   type Pool_Index is range 0 .. Parameters.Interrupt_Clocks + 1;
   for Pool_Index'Size use 8;

   -----------------------
   -- Local definitions --
   -----------------------

   Pool : array (Pool_Index) of aliased Clock_Descriptor;
   --  Pool of clocks

   Last : Pool_Index := 0;
   --  Pointing to last allocated clock in pool

   Lookup : array (Interrupt_ID) of Pool_Index;
   --  Array for translating interrupt IDs to pool index

   Stack : Clock_Stack;
   --  Stack of interrupted timers

   Top : Stack_Index := 0;
   --  Index of free place on stack

   ETC : Clock_Id;
   --  The currently running execution time clock

   Idle : constant Clock_Id := Pool (0)'Access;
   --  Clock of the pseudo idle thread

   Sentinel : aliased Alarm_Descriptor := (Timeout => CPU_Time'Last,
                                           others  => <>);
   --  Alarm of clocks when not set

   -----------------------
   -- Local subprograms --
   -----------------------

   function Active (Clock : Clock_Id) return Boolean;
   pragma Inline_Always (Active);
   --  Returns true when the given clock is active (running)

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID);
   --  Handler for the TMU COMPARE interrupt

   procedure Initialize_Clock
     (Clock    : Clock_Id;
      Capacity : Natural);
   --  Initializes the given clock

   procedure Update_ETC (Clock : Clock_Id);
   --  Swaps ETC to the given clock

   ------------
   -- Active --
   ------------

   function Active (Clock : Clock_Id) return Boolean is
   begin
      return Clock = ETC;
   end Active;

   ------------
   -- Cancel --
   ------------

   procedure Cancel (Alarm : not null Alarm_Id) is
      Clock : constant Clock_Id := Alarm.Clock;
   begin

      pragma Assert (Clock /= null);

      --  Check if Alarm is set

      if Alarm = Clock.First_Alarm then

         Clock.First_Alarm := Sentinel'Access;

         if Active (Clock) then
            Peripherals.Set_Compare (CPU_Time'Last);
         end if;

      end if;

   end Cancel;

   -----------
   -- Clock --
   -----------

   function Clock (Alarm : not null Alarm_Id) return Clock_Id is
   begin
      return Alarm.Clock;
   end Clock;

   ---------------------
   -- Compare_Handler --
   ---------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID) is
      Clock : constant Clock_Id := Stack (Top - 1);
      Alarm : constant Alarm_Id := Clock.First_Alarm;
   begin

      pragma Assert (Id = Peripherals.TMU);
      pragma Assert (Clock /= ETC);

      --  Call alarm handler if set and expired

      if Alarm.Timeout <= Clock.Count then

         Clock.First_Alarm := Sentinel'Access;

         Alarm.Timeout := CPU_Time'First;
         Alarm.Handler (Alarm.Data);

      end if;

   end Compare_Handler;

   ----------------
   -- Enter_Idle --
   ----------------

   procedure Enter_Idle (Id : Thread_Id) is
   begin
      pragma Assert (ETC = Id.Active_Clock);
      pragma Assert (Id.Active_Clock = Id.Clock'Access);

      Id.Active_Clock := Idle;

      Update_ETC (Idle);

   end Enter_Idle;

   ---------------------
   -- Enter_Interrupt --
   ---------------------

   procedure Enter_Interrupt (Id : Interrupt_ID) is
      I : constant Pool_Index := Lookup (Id);
   begin
      pragma Assert (Top < Stack'Last);
      pragma Assert (I > 0);

      Stack (Top) := ETC;
      Top := Top + 1;

      Update_ETC (Pool (I)'Access);

   end Enter_Interrupt;

   ----------------------
   -- Initialize_Alarm --
   ----------------------

   procedure Initialize_Alarm
     (Alarm   : not null Alarm_Id;
      Clock   : not null Clock_Id;
      Handler : not null Alarm_Handler;
      Data    : System.Address;
      Success : out Boolean)
   is
   begin

      if Clock.Capacity > 0 then

         Clock.Capacity := Clock.Capacity - 1;

         Alarm.Clock   := Clock;
         Alarm.Handler := Handler;
         Alarm.Data    := Data;

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
      Clock.all := (Count       => CPU_Time'First,
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

   procedure Initialize_TMU (Environment_Thread : Thread_Id) is
   begin
      --  Initialize execution time clock of environment thread

      Initialize_Thread_Clock (Environment_Thread);

      --  Initialize execution time clock for idling, no alarms

      Initialize_Clock (Idle, 0);

      --  Activate clock of environment thread

      ETC := Environment_Thread.Clock'Access;
      Update_ETC (ETC);

      --  Install COMPARE interrupt handler

      Interrupts.Attach_Handler (Compare_Handler'Access, Peripherals.TMU);

   end Initialize_TMU;

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
      pragma Assert (ETC = Idle);
      pragma Assert (Id.Active_Clock = Idle);

      Id.Active_Clock := Clock;

      Update_ETC (Clock);

   end Leave_Idle;

   ---------------------
   -- Leave_Interrupt --
   ---------------------

   procedure Leave_Interrupt is
   begin
      pragma Assert (Top > 0);

      Top := Top - 1;

      Update_ETC (Stack (Top));

   end Leave_Interrupt;

   ---------
   -- Set --
   ---------

   procedure Set
     (Alarm   : not null Alarm_Id;
      Timeout : CPU_Time)
   is
      Clock : constant Clock_Id := Alarm.Clock;
   begin

      pragma Assert (Clock /= null);

      --  Set timeout

      Alarm.Timeout := Timeout;

      --  Set clock with alarm and update compare if clock is active

      Clock.First_Alarm := Alarm;

      if Active (Clock) then
         Peripherals.Set_Compare (Timeout);
      end if;

   end Set;

   -------------------
   -- Time_Of_Clock --
   -------------------

   function Time_Of_Clock (Clock : not null Clock_Id) return CPU_Time is
   begin

      --  If clock is not active return base time

      if Active (Clock) then
         return CPU_Time (Peripherals.Get_Count);
      else
         return Clock.Count;
      end if;

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

   function Time_Of_Alarm (Alarm : not null Alarm_Id) return CPU_Time is
   begin
      return Alarm.Timeout;
   end Time_Of_Alarm;

   ----------------
   -- Update_ETC --
   ----------------

   procedure Update_ETC (Clock : Clock_Id) is
   begin
      pragma Assert (Clock /= null);

      Peripherals.Swap_Context (Clock.First_Alarm.Timeout,
                                Clock.Count,
                                ETC.Count);

      ETC := Clock;

   end Update_ETC;

end System.BB.TMU;
