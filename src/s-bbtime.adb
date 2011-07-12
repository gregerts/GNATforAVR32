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

   use type CPU.Word;
   use type Interrupts.Interrupt_ID;

   -----------------------
   -- Local definitions --
   -----------------------

   Max_Compare : constant := CPU.Word'Last / 2;
   --  Maximal value set to COMPARE register

   ETC : Clock_Id;
   --  The currently running execution time clock

   RTC : aliased Clock_Descriptor;
   --  The real-time clock

   Idle : aliased Clock_Descriptor;
   --  Clock of the pseudo idle thread

   Sentinel : aliased Alarm_Descriptor := (Timeout => Time'Last, others => <>);
   --  Always the last alarm in the queue of every clock

   -----------------------
   -- Local subprograms --
   -----------------------

   function Active (Clock : Clock_Id) return Boolean;
   pragma Inline_Always (Active);
   --  Returns true when the given clock is active (running)

   procedure Alarm_Wrapper (Clock : Clock_Id);
   pragma Inline (Alarm_Wrapper);
   --  Calls all expired alarm handlers for the given clock

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID);
   --  Handler for the COMPARE interrupt

   procedure Context_Switch (First : Thread_Id);
   pragma Export (Asm, Context_Switch, "timer_context_switch");
   --  Changes time context to first thread

   procedure Initialize_Clock
     (Clock    : Clock_Id;
      Capacity : Natural);
   --  Initializes the given clock

   function Remaining (Clock : Clock_Id) return Time;
   pragma Inline_Always (Remaining);
   --  Returns time until first alarm of clock expires

   procedure Update_ETC (Clock : Clock_Id);
   --  Swaps ETC to the given clock

   procedure Update_Compare;
   --  Update COMPARE as timeout of active clock has changed

   ------------
   -- Active --
   ------------

   function Active (Clock : Clock_Id) return Boolean is
   begin
      return Clock = RTC'Access or else Clock = ETC;
   end Active;

   -------------------
   -- Alarm_Wrapper --
   -------------------

   procedure Alarm_Wrapper (Clock : Clock_Id) is
      Alarm : Alarm_Id := Clock.First_Alarm;
   begin

      --  Remove all expired alarms from queue and call handlers

      while Alarm.Timeout <= Clock.Base_Time loop

         Clock.First_Alarm := Alarm.Next;
         Alarm.Next := null;

         Alarm.Handler (Alarm.Data);

         Alarm := Clock.First_Alarm;

      end loop;

   end Alarm_Wrapper;

   ------------
   -- Cancel --
   ------------

   procedure Cancel (Alarm : not null Alarm_Id) is
      Clock : constant Clock_Id := Alarm.Clock;
      Aux : Alarm_Id;

   begin

      pragma Assert (Clock /= null);

      --  Nothing to be done if the alarm is not set

      if Alarm.Next = null then
         return;
      end if;

      --  Check if Alarm is first in queue

      if Alarm = Clock.First_Alarm then

         --  Remove Alarm from head of queue, update COMPARE if needed

         Clock.First_Alarm := Alarm.Next;

         if Active (Clock) then
            Update_Compare;
         end if;

      else

         --  Find element Aux before Alarm in queue

         Aux := Clock.First_Alarm;

         while Aux.Next /= Alarm loop
            Aux := Aux.Next;
         end loop;

         --  Remove alarm from queue

         Aux.Next := Alarm.Next;

      end if;

      Alarm.Next := null;

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
   begin

      pragma Assert (Id = Peripherals.COMPARE);

      Alarm_Wrapper (RTC'Access);
      Alarm_Wrapper (ETC);

   end Compare_Handler;

   --------------------
   -- Context_Switch --
   --------------------

   procedure Context_Switch (First : Thread_Id) is
   begin
      Update_ETC (First.Clock'Access);
   end Context_Switch;

   ------------------
   -- Elapsed_Time --
   ------------------

   function Elapsed_Time (Clock : not null Clock_Id) return Time is
      T : Time := Clock.Base_Time;
   begin

      if Active (Clock) then

         T := T + Time (CPU.Get_Count);

         CPU.Barrier;

         if T < Clock.Base_Time then
            T := Clock.Base_Time;
         end if;

      end if;

      return T;

   end Elapsed_Time;

   ----------------
   -- Enter_Idle --
   ----------------

   procedure Enter_Idle (Id : Thread_Id) is
   begin
      pragma Assert (ETC = Id.Clock'Access);
      Update_ETC (Idle'Access);
   end Enter_Idle;

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

         Alarm.all := (Clock   => Clock,
                       Timeout => Time'First,
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

   -----------------------------
   -- Initialize_Thread_Clock --
   -----------------------------

   procedure Initialize_Thread_Clock (Id : Thread_Id) is
   begin
      pragma Assert (Id /= null);

      --  Only one alarm for execution time clocks in Ravenscar

      Initialize_Clock (Id.Clock'Access, 1);

   end Initialize_Thread_Clock;

   -----------------------
   -- Initialize_Timers --
   -----------------------

   procedure Initialize_Timers (Environment_Thread : Thread_Id) is
   begin
      --  Initialize execution time clock of environment thread

      Initialize_Thread_Clock (Environment_Thread);

      --  Initialize execution time clock for idling, no alarms

      Initialize_Clock (Idle'Access, 0);

      --  Initialize real-time clock, no limit on alarms

      Initialize_Clock (RTC'Access, Natural'Last);

      --  Activate clock of environment thread

      ETC := Environment_Thread.Clock'Access;
      Update_ETC (ETC);

      --  Install COMPARE interrupt handler

      Interrupts.Attach_Handler (Compare_Handler'Access, Peripherals.COMPARE);

   end Initialize_Timers;

   ----------------
   -- Leave_Idle --
   ----------------

   procedure Leave_Idle (Id : Thread_Id) is
   begin

      if ETC = Idle'Access then
         Update_ETC (Id.Clock'Access);
      end if;

      pragma Assert (ETC = Id.Clock'Access);

   end Leave_Idle;

   ---------------------
   -- Real_Time_Clock --
   ---------------------

   function Real_Time_Clock return Clock_Id is
   begin
      return RTC'Access;
   end Real_Time_Clock;

   ---------------
   -- Remaining --
   ---------------

   function Remaining (Clock : Clock_Id) return Time is
      T : constant Time := Clock.First_Alarm.Timeout;
   begin
      return T - Time'Min (T, Clock.Base_Time);
   end Remaining;

   ---------
   -- Set --
   ---------

   procedure Set
     (Alarm   : not null Alarm_Id;
      Timeout : Time)
   is
      Clock : constant Clock_Id := Alarm.Clock;
      Aux : Alarm_Id;

   begin

      pragma Assert (Clock /= null);
      pragma Assert (Timeout < Time'Last);
      pragma Assert (Alarm.Next = null);

      --  Set timeout

      Alarm.Timeout := Timeout;

      --  Check if Alarm is to be first in queue

      if Timeout < Clock.First_Alarm.Timeout then

         --  Insert Alarm first in queue, update COMPARE if needed

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

      end if;

      pragma Assert (Alarm.Next /= null);

   end Set;

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

   function Time_Of_Alarm (Alarm : not null Alarm_Id) return Time is
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
      Diff : constant Time
        := Time'Min (Remaining (RTC'Access), Remaining (ETC));
   begin
      CPU.Adjust_Compare (CPU.Word (Time'Min (Diff, Max_Compare)));
   end Update_Compare;

   ----------------
   -- Update_ETC --
   ----------------

   procedure Update_ETC (Clock : Clock_Id) is
      Prev : CPU.Word;
   begin
      pragma Assert (Clock /= null);

      CPU.Reset_Count (Prev);

      RTC.Base_Time := RTC.Base_Time + Time (Prev);
      ETC.Base_Time := ETC.Base_Time + Time (Prev);

      ETC := Clock;

      Update_Compare;

   end Update_ETC;

end System.BB.Time;
