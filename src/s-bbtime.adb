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
with System.BB.Interrupts;
with System.BB.Parameters;

package body System.BB.Time is

   package CPU renames System.BB.CPU_Primitives;

   use type CPU.Word;
   use type Interrupts.Interrupt_ID;

   -----------------------
   -- Local definitions --
   -----------------------

   Max_Compare : constant := CPU.Word'Last - 2 ** 16;
   --  Maximal value set to COMPARE register

   Sentinel : aliased Alarm_Descriptor := (Timeout => Time'Last, others => <>);
   --  Always the last alarm in the queue of every clock

   First_Alarm : Alarm_Id := Sentinel'Access;
   --  First alarm of the real-time clock

   Base_Time : Time := Time'First;
   --  Base time of the real-time clock

   Defer_Updates : Boolean := False;
   --  True if updates to COMPARE are to be deferred

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID);
   --  Handler for the COMPARE interrupt

   procedure Update_Compare;
   --  Update COMPARE as timeout of active clock has changed

   ------------
   -- Cancel --
   ------------

   procedure Cancel (Alarm : not null Alarm_Id) is
      Aux : Alarm_Id;
   begin

      --  Nothing to be done if the alarm is not set

      if Alarm.Next = null then
         return;
      end if;

      --  Check if Alarm is first in queue

      if Alarm = First_Alarm then

         --  Remove Alarm from head of queue, update COMPARE if needed

         First_Alarm := Alarm.Next;

         if not Defer_Updates then
            Update_Compare;
         end if;

      else

         --  Find element Aux before Alarm in queue

         Aux := First_Alarm;

         while Aux.Next /= Alarm loop
            Aux := Aux.Next;
         end loop;

         --  Remove alarm from queue

         Aux.Next := Alarm.Next;

      end if;

      Alarm.Next := null;

   end Cancel;

   ---------------------
   -- Compare_Handler --
   ---------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID) is
      Alarm : Alarm_Id;
   begin

      pragma Assert (Id = Peripherals.COMPARE);

      --  Update base time of real time clock

      declare
         Prev : CPU.Word;
      begin
         CPU.Reset_Count (Prev);
         Base_Time := Base_Time + Time (Prev);
      end;

      --  Call all expired alarm handlers, defer COMPARE updates

      Defer_Updates := True;

      loop

         Alarm := First_Alarm;
         exit when Alarm.Timeout > Base_Time;

         --  Remove Alarm from queue and call handler

         First_Alarm := Alarm.Next;
         Alarm.Next := null;
         Alarm.Handler (Alarm.Data);

      end loop;

      Defer_Updates := False;

      --  Now update COMPARE register to reflect new alarm status

      Update_Compare;

   end Compare_Handler;

   ----------------------
   -- Initialize_Alarm --
   ----------------------

   procedure Initialize_Alarm
     (Alarm   : not null Alarm_Id;
      Handler : not null Alarm_Handler;
      Data    : System.Address)
   is
   begin
      Alarm.Handler := Handler;
      Alarm.Data    := Data;
      Alarm.Next    := null;
   end Initialize_Alarm;

   -----------------------
   -- Initialize_Timers --
   -----------------------

   procedure Initialize_Timers is
   begin
      --  Install COMPARE interrupt handler

      Interrupts.Attach_Handler (Compare_Handler'Access, Peripherals.COMPARE);

      --  Update COMPARE for the first time

      Update_Compare;

   end Initialize_Timers;

   ---------------------
   -- Monotonic_Clock --
   ---------------------

   function Monotonic_Clock return Time is
      Base  : Time;
      Count : CPU.Word;

   begin

      --  Get consisting reading of base time and COUNT

      loop

         Base  := Base_Time;
         Count := CPU.Get_Count;

         CPU.Barrier;

         exit when Base = Base_Time;

      end loop;

      return Base + Time (Count);

   end Monotonic_Clock;

   ---------
   -- Set --
   ---------

   procedure Set
     (Alarm   : not null Alarm_Id;
      Timeout : Time)
   is
      Aux : Alarm_Id;
   begin

      pragma Assert (Timeout < Time'Last);
      pragma Assert (Alarm.Next = null);

      --  Set timeout

      Alarm.Timeout := Timeout;

      --  Check if Alarm is to be first in queue

      if Timeout < First_Alarm.Timeout then

         --  Insert Alarm first in queue, update COMPARE in needed

         Alarm.Next := First_Alarm;
         First_Alarm := Alarm;

         if not Defer_Updates then
            Update_Compare;
         end if;

      else

         --  Find element Aux where Aux.Next.Timeout > Timeout

         Aux := First_Alarm;

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
      Aux : Time := First_Alarm.Timeout;
   begin

      Aux := Aux - Time'Min (Aux, Base_Time);
      Aux := Time'Min (Aux, Max_Compare);

      CPU.Adjust_Compare (CPU.Word (Aux));

   end Update_Compare;

end System.BB.Time;
