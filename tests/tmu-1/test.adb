with GNAT.IO;
with Utilities;
with Ada.Execution_Time;
with Ada.Real_Time.Timing_Events;
with Ada.Task_Identification;

use GNAT.IO;
use Utilities;
use Ada.Execution_Time;
use Ada.Real_Time;
use Ada.Real_Time.Timing_Events;
use Ada.Task_Identification;

package body Test is

   subtype Task_Index is Integer range 1 .. Number_Of_Tasks;

   type Task_Array is array (Task_Index) of Task_Id;
   type Time_Array is array (Natural range <>) of CPU_Time;

   protected Poller is
      procedure Initialize;
      procedure Handler (Event : in out Timing_Event);
      entry Wait;
      pragma Priority (System.Any_Priority'Last);
   private
      Event : Timing_Event;
      Next  : Time;
      Done  : Boolean;
   end Poller;

   procedure Put is new Put_Hex (Time);
   procedure Put is new Put_Hex (CPU_Time);

   -----------------------
   -- Local definitions --
   -----------------------

   Epoch : constant Time := Time_First + Milliseconds (100);

   Tasks : Task_Array;

   Polling_Time   : Time;
   Idle_Time      : CPU_Time;
   Interrupt_Time : Time_Array (System.Interrupt_Priority);
   Task_Time      : Time_Array (Task_Index);

   --------------
   -- Periodic --
   --------------

   task body Periodic is
      Next : Time := Epoch;
   begin
      loop
         delay until Next;
         Busy_Wait (C);
         Next := Next + Microseconds (T);
      end loop;
   end Periodic;

   ------------
   -- Poller --
   ------------

   protected body Poller is

      procedure Initialize is
      begin

         Done := False;
         Next := Epoch + Microseconds (Major_Period);

         Event.Set_Handler (Next, Handler'Access);

      end Initialize;

      procedure Handler (Event : in out Timing_Event) is
      begin

         if Wait'Count > 0 then

            Polling_Time := Clock;

            for I in reverse System.Interrupt_Priority loop
               Interrupt_Time (I) := Interrupt_Clock (I);
            end loop;

            for I in Task_Index loop
               Task_Time (I) := Clock (Tasks (I));
            end loop;

            Idle_Time := Idle_Clock;

            Done := True;

         end if;

         Next := Next + Microseconds (Major_Period);

         Event.Set_Handler (Next, Handler'Access);

      end Handler;

      entry Wait when Done is
      begin
         Done := False;
      end Wait;

   end Poller;

   ---------
   -- Run --
   ---------

   procedure Run is
   begin

      New_Line;
      Put_Line ("SYNC");

      loop

         Poller.Wait;

         Put (Polling_Time);
         Put (':');
         Put (Idle_Time);

         for I in System.Interrupt_Priority loop
            Put (':');
            Put (Interrupt_Time (I));
         end loop;

         for I in Task_Index loop
            Put (':');
            Put (Task_Time (I));
         end loop;

         New_Line;

      end loop;

   end Run;

begin

   Tasks (1) := T_A'Identity;
   Tasks (2) := T_B'Identity;
   Tasks (3) := T_C'Identity;
   Tasks (4) := T_D'Identity;
   Tasks (5) := Current_Task;

   Poller.Initialize;

end Test;
