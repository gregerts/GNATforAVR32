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

   Alarm_Interrupt : constant := Peripherals.TC_2;
   Clock_Interrupt : constant := Peripherals.TC_1;
   --  Clock and alarm interrupts

   Clock_Period : constant := 2 ** Timer_Interval'Size;
   --  Period between clock overflows

   Base_Time : Time := 0;
   pragma Volatile (Base_Time);
   --  Base of clock (i.e. MSP), stored in memory

   Last_Alarm : aliased Alarm_Descriptor := (Handler => null,
                                             Data    => System.Null_Address,
                                             Timeout => Time'Last,
                                             Next    => null,
                                             Prev    => null);
   --  Last alarm in queue

   First_Alarm : Alarm_Id := Last_Alarm'Access;
   --  First alarm in queue

   Pending_Alarm : Alarm_Id := null;
   --  Alarm corrensponding to the hardware timer if set

   Defer_Update : Boolean := False;
   --  Flags that alarm timer updates should be deferred

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Clock_Handler (Interrupt : Interrupts.Interrupt_ID);
   --  Handler for the clock interrupt

   procedure Clear (Alarm : Alarm_Id);
   pragma Inline_Always (Clear);
   --  Procedure to clear an alarm

   procedure Update_Alarm_Timer;
   --  Procedure that updates the hardware alarm timer

   ------------
   -- Cancel --
   ------------

   procedure Cancel (Alarm : Alarm_Id)
   is
   begin

      pragma Assert (Alarm /= null);

      --  Nothing to be done if the alarm is not set

      if Alarm.Next = null then
         return;
      end if;

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

   end Cancel;

   -----------
   -- Clear --
   -----------

   procedure Clear (Alarm : Alarm_Id) is
   begin
      Alarm.Timeout := Time'First;
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

      --  If a clock interrupt is pending the task has the highest
      --  priority or is executing within kernel.

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
      Now : Time;
   begin

      --  Make sure we are handling the right interrupt

      pragma Assert (Interrupt = Alarm_Interrupt
                       or Interrupt = Clock_Interrupt);

      --  Clear alarm interrupt, possible pending alarm is handled

      Peripherals.Clear_Alarm_Interrupt;

      --  Read the time, update base time if and clear clock
      --  overflow interrupt if necessary.

      declare
         B : Time           := Base_Time;
         C : Timer_Interval := Peripherals.Read_Clock;
      begin

         if Peripherals.Pending_Clock then

            Peripherals.Clear_Clock_Interrupt;

            B := B + Clock_Period;
            C := Peripherals.Read_Clock;

            Base_Time := B;

         end if;

         Now := B + Time (C);

      end;

      --  Exit loop when first alarm is in the future. Else remove
      --  first alarm from queue, clear it and call its handler.
      --  Defer updates to hardware timer to end of handler

      Defer_Update := True;

      while First_Alarm.Timeout <= Now loop

         declare
            Alarm : constant Alarm_Id := First_Alarm;
         begin
            pragma Assert (Alarm.Handler /= null);

            First_Alarm      := Alarm.Next;
            First_Alarm.Prev := null;

            Clear (Alarm);
            Alarm.Handler (Alarm.Data);
         end;

      end loop;

      --  Clear the defer update flag and update alarm timer

      Defer_Update := False;

      Update_Alarm_Timer;

   end Clock_Handler;

   ----------------------
   -- Initialize_Alarm --
   ----------------------

   procedure Initialize_Alarm
     (Alarm   : not null Alarm_Id;
      Handler : not null Alarm_Handler;
      Data    : System.Address)
   is
   begin

      pragma Assert (Alarm.Handler = null);

      Alarm.Handler := Handler;
      Alarm.Data    := Data;

      Clear (Alarm);

   end Initialize_Alarm;

   -----------------------
   -- Initialize_Timers --
   -----------------------

   procedure Initialize_Timers is
   begin

      --  Install clock handler for both clock overflow and hardware
      --  alarm timer interrupts.

      Interrupts.Attach_Handler (Clock_Handler'Access, Alarm_Interrupt);
      Interrupts.Attach_Handler (Clock_Handler'Access, Clock_Interrupt);

   end Initialize_Timers;

   ---------
   -- Set --
   ---------

   procedure Set
     (Alarm   : Alarm_Id;
      Timeout : Time)
   is
      Aux : Alarm_Id := First_Alarm;
   begin

      --  Set alarm timeout

      Alarm.Timeout := Timeout;

      --  Search for element Aux where Aux.Timeout > Timeout

      while Aux.Timeout <= Timeout loop
            Aux := Aux.Next;
      end loop;

      --  Insert before Aux (always before Last_Alarm)

      Alarm.Next := Aux;
      Alarm.Prev := Aux.Prev;
      Aux.Prev := Alarm;

      --  Check if this alarm is to be first in queue

      if Alarm.Prev = null then
         First_Alarm := Alarm;
         Update_Alarm_Timer;
      else
         Alarm.Prev.Next := Alarm;
      end if;

   end Set;

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

      if Defer_Update or else Pending_Alarm = First_Alarm then
         return;
      end if;

      --  Cancel any pending hardware alarm

      if Pending_Alarm /= null then
         Peripherals.Cancel_Alarm;
         Pending_Alarm := null;
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
         Pending_Alarm := First_Alarm;
      end if;

   end Update_Alarm_Timer;

end System.BB.Time;
