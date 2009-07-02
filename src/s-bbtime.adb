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
--             Copyright (C) 2008-2009, Kristoffer N. Gregertsen            --
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

with System.BB.Interrupts;
--  Used for Attach_Handler

package body System.BB.Time is

   use type Peripherals.Timer_Interval;

   subtype Timer_Interval is Peripherals.Timer_Interval;

   -----------------------
   -- Local definitions --
   -----------------------

   Clock_Period : constant := 2 ** Timer_Interval'Size;
   --  Period between clock overflows

   Base_Time : Time := 0;
   pragma Volatile (Base_Time);
   --  Base of clock (i.e. MSP), stored in memory

   Last_Alarm : aliased Alarm_Timer := (Timeout => Time'Last,
                                        Handler => null,
                                        Data    => Null_Address,
                                        Next    => null,
                                        Prev    => null);
   --  Last alarm in queue

   First_Alarm : Alarm_Id := Last_Alarm'Access;
   --  First alarm in queue

   Defer_Update : Boolean := False;
   --  Flags that alarm timer updates should be deferred

   Pending_Alarm : Boolean := False;
   --  The alarm timer is used to trigger alarms between two periodic
   --  interrupts. It is however possible that due to calculations
   --  delay an alarm could expire after the clock interrupt. If so
   --  the Clock Handler should do nothing with the alarms. This flag
   --  shows if an alarm is pending.

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Alarm_Wrapper (Interrupt : Interrupts.Interrupt_ID);
   --  Handler for the timing event interrupt

   procedure Clock_Handler (Interrupt : Interrupts.Interrupt_ID);
   --  Handler for the clock interrupt

   procedure Clear (Alarm : Alarm_Id);
   pragma Inline_Always (Clear);
   --  Procedure to clear an alarm

   procedure Update_Alarm_Timer;
   --  Procedure that updates the event timer

   -------------------
   -- Alarm_Wrapper --
   -------------------

   procedure Alarm_Wrapper (Interrupt : Interrupts.Interrupt_ID) is
      Now, Diff : Time;
      Alarm     : Alarm_Id := First_Alarm;

   begin

      --  Make sure we are handling the right interrupt and there is
      --  an event pending.

      pragma Assert (Interrupt = System.BB.Peripherals.TC_1);
      pragma Assert (Pending_Alarm);
      pragma Assert (Alarm /= null);
      pragma Assert (Alarm.Timeout <= Clock);

      --  Clear interrupt and set the defer update flag

      Peripherals.Clear_Alarm_Interrupt;

      Defer_Update := True;

      loop

         --  Remove first event from queue. The queue has to be in a
         --  consistent state prior to calling the handler since it
         --  may in turn call procedures that manipulates the queue.

         First_Alarm     := Alarm.Next;
         Alarm.Next.Prev := null;

         --  Clear event and call handler

         declare
            Handler : constant Alarm_Handler  := Alarm.Handler;
            Data    : constant System.Address := Alarm.Data;
         begin
            pragma Assert (Handler /= null);

            Clear   (Alarm);
            Handler (Data);
         end;

         --  Read clock and update base time if there is a pending
         --  clock interrupt in order to avoid unecessary interrupts.

         declare
            B : Time           := Base_Time;
            C : Timer_Interval := Peripherals.Read_Clock;

         begin

            if Peripherals.Pending_Clock then

               B := B + Clock_Period;
               C := Peripherals.Read_Clock;

               Base_Time := B;

               Peripherals.Clear_Clock_Interrupt;

            end if;

            Now := B + Time (C);
         end;

         --  Get first event from queue, may have been updated

         Alarm := First_Alarm;

         exit when Alarm.Timeout > Now;

      end loop;

      --  Clear the defer update flag

      Defer_Update := False;

      --  Alarm is in future, set timer if alarm within clock period

      Diff          := Alarm.Timeout - Now;
      Pending_Alarm := Diff < Clock_Period;

      if Pending_Alarm then
         Peripherals.Set_Alarm (Timer_Interval (Diff));
      end if;

   end Alarm_Wrapper;

   --------------------
   -- Cancel_Handler --
   --------------------

   procedure Cancel_Handler (Alarm : Alarm_Id)
   is
   begin

      pragma Assert (Alarm /= null);

      if Alarm.Handler /= null then

         --  Check if Alarm is first in queue

         if Alarm.Prev = null then

            pragma Assert (Alarm = First_Alarm);

            First_Alarm     := Alarm.Next;
            Alarm.Next.Prev := null;

            Update_Alarm_Timer;

         else

            Alarm.Prev.Next := Alarm.Next;
            Alarm.Next.Prev := Alarm.Prev;

         end if;

         Clear (Alarm);

      end if;

   end Cancel_Handler;

   -----------
   -- Clear --
   -----------

   procedure Clear (Alarm : Alarm_Id) is
   begin
      Alarm.Timeout := Time'First;
      Alarm.Handler := null;
      Alarm.Data    := Null_Address;
      Alarm.Next    := null;
      Alarm.Prev    := null;
   end Clear;

   -----------
   -- Clock --
   -----------

   function Clock return Time is
      B : Time;
      C : Timer_Interval;

   begin

      --  Clock is sum of base time and peripheral clock, read again
      --  if base time is updated by clock interrupt after being read.

      loop
         B := Base_Time;
         C := Peripherals.Read_Clock;
         exit when B = Base_Time;
      end loop;

      --  If a clock interrupt is pending the task has to have the
      --  highest priority or is executing within kernel. The
      --  interrupt may have occured after reading B and C.

      if Peripherals.Pending_Clock then
         B := B + Clock_Period;
         C := Peripherals.Read_Clock;
      end if;

      return B + Time (C);

   end Clock;

   -------------------
   -- Clock_Handler --
   -------------------

   procedure Clock_Handler (Interrupt : Interrupts.Interrupt_ID) is
      Base      : constant Time := Base_Time + Clock_Period;
      Now, Diff : Time;

   begin
      --  Check that we are in the right handler

      pragma Assert (Interrupt = System.BB.Peripherals.TC_2);

      Peripherals.Clear_Clock_Interrupt;

      --  The clock timer has overflowed

      Base_Time := Base;

      if not Pending_Alarm then

         --  Find time remaining to first alarm

         Now := Base + Time (Peripherals.Read_Clock);

         if First_Alarm.Timeout > Now then
            Diff := First_Alarm.Timeout - Now;
         else
            Diff := 1;
         end if;

         --  Set timer if the alarm is within a clock period

         if Diff < Clock_Period then
            Peripherals.Set_Alarm (Peripherals.Timer_Interval (Diff));
            Pending_Alarm := True;
         end if;

      end if;

   end Clock_Handler;

   -----------------------
   -- Initialize_Timers --
   -----------------------

   procedure Initialize_Timers is
   begin
      --  Install clock handler

      Interrupts.Attach_Handler
        (Clock_Handler'Access, System.BB.Peripherals.TC_2);

      --  Install alarm handler

      Interrupts.Attach_Handler
        (Alarm_Wrapper'Access, System.BB.Peripherals.TC_1);

   end Initialize_Timers;

   -----------------
   -- Set_Handler --
   -----------------

   procedure Set_Handler
     (Alarm   : Alarm_Id;
      Timeout : Time;
      Handler : Alarm_Handler;
      Data    : System.Address)
   is
      Aux : Alarm_Id := Last_Alarm'Access;
   begin

      pragma Assert (Alarm.Handler = null);
      pragma Assert (Handler /= null);

      --  Set alarm timeout, handler and data

      Alarm.Timeout := Timeout;
      Alarm.Handler := Handler;
      Alarm.Data    := Data;

      --  Search queue from end for element Aux where Aux.Prev = null
      --  (first in queue) or Aux.Prev.Timeout <= Alarm.Timeout

      while Aux.Prev /= null and then Aux.Prev.Timeout > Timeout loop
         Aux := Aux.Prev;
      end loop;

      --  Insert before Aux (always before Last_Alarm)

      Alarm.Next := Aux;
      Alarm.Prev := Aux.Prev;
      Aux.Prev   := Alarm;

      --  If Alarm.Prev is null then Alarm is first in queue

      if Alarm.Prev = null then

         pragma Assert (Aux = First_Alarm);

         --  Set First_Alarm to Alarm and update alarm timer

         First_Alarm := Alarm;

         Update_Alarm_Timer;

      else

         Alarm.Prev.Next := Alarm;

      end if;

   end Set_Handler;

   -------------------
   -- Time_Of_Alarm --
   -------------------

   function Time_Of_Alarm (Alarm : Alarm_Id) return Time is
   begin
      return Alarm.Timeout;
   end Time_Of_Alarm;

   ------------------------
   -- Update_Alarm_Timer --
   ------------------------

   procedure Update_Alarm_Timer is
      Now, Diff : Time;
   begin

      --  Return if updates are deferred

      if Defer_Update then
         return;
      end if;

      --  Cancel any pending alarm

      if Pending_Alarm then
         Peripherals.Cancel_Alarm;
         Pending_Alarm := False;
      end if;

      --  Find time remaining to first alarm

      Now := Clock;

      if First_Alarm.Timeout > Now then
         Diff := First_Alarm.Timeout - Now;
      else
         Diff := 1;
      end if;

      --  Set timer if alarm is within a clock period

      if Diff < Clock_Period then
         Peripherals.Set_Alarm (Timer_Interval (Diff));
         Pending_Alarm := True;
      end if;

   end Update_Alarm_Timer;

end System.BB.Time;
