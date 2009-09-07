with Ada.Execution_Time, Ada.Task_Identification, Ada.Real_Time.Timing_Events,
  GNAT.IO, System, Epoch_Support, Utilities;
use Ada.Execution_Time, Ada.Task_Identification, Ada.Real_Time.Timing_Events,
  GNAT.IO, System, Epoch_Support, Utilities;

package body Execution_Time_Poller is

   type Task_Array is array (Positive range <>) of Task_Id;
   type CPU_Time_Array is array (Positive range <>) of CPU_Time;

   procedure Put is new Put_Hex (Time);
   procedure Put is new Put_Hex (CPU_Time);

   protected Poller is

      procedure Start;
      entry Wait;

   private

      pragma Priority (Any_Priority'Last);

      procedure Handler (Event : in out Timing_Event);

      Event : Timing_Event;
      Next  : Time;
      Done  : Boolean;

   end Poller;

   task Idle_Task is
      pragma Priority (Priority'First);
      pragma Storage_Size (256);
   end Idle_Task;

   ----------
   -- Data --
   ----------

   Tasks : access Task_Array;
   Last  : Natural;

   Major_Period   : Time_Span;
   Polling_Time   : Time;

   Interrupt_Time : CPU_Time_Array (Interrupt_Priority);
   Task_Time      : access CPU_Time_Array;
   Idle_Time      : CPU_Time;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (N : Positive;
      P : Time_Span)
   is
   begin

      Major_Period := P;

      Tasks     := new Task_Array (1 .. N);
      Task_Time := new CPU_Time_Array (1 .. N);

      Last := 0;

   end Initialize;

   --------------
   -- Register --
   --------------

   procedure Register (Tid : Task_Id) is
   begin

      pragma Assert (Tasks /= null and then Last < Tasks'Length);

      Last := Last + 1;
      Tasks (Last) := Tid;

   end Register;

   ---------
   -- Run --
   ---------

   procedure Run is
   begin

      pragma Assert (Task_Time /= null);

      Poller.Start;

      delay until Epoch;

      New_Line;
      Put_Line ("SYNC");

      loop

         Poller.Wait;

         Put (Polling_Time);
         Put (':');

         for I in reverse System.Interrupt_Priority loop
            Put (Interrupt_Time (I));
            Put (':');
         end loop;

         for I in 1 .. Last loop
            Put (Task_Time (I));
            Put (':');
         end loop;

         Put (Idle_Time);

         New_Line;

      end loop;

   end Run;

   ------------
   -- Poller --
   ------------

   protected body Poller is

      -----------
      -- Start --
      -----------

      procedure Start is
      begin

         Done := False;
         Next := Epoch_Support.Epoch + Major_Period;

         Event.Set_Handler (Next, Handler'Access);

      end Start;

      ----------
      -- Wait --
      ----------

      entry Wait when Done is
      begin
         Done := False;
      end Wait;

      -------------
      -- Handler --
      -------------

      procedure Handler (Event : in out Timing_Event) is
      begin

         if Wait'Count > 0 then

            Polling_Time := Clock;

            for I in reverse System.Interrupt_Priority loop
               Interrupt_Time (I) := Interrupt_Clock (I);
            end loop;

            for I in 1 .. Last loop
               Task_Time (I) := Clock (Tasks (I));
            end loop;

            Idle_Time := Clock (Idle_Task'Identity);

            Done := True;

         end if;

         Next := Next + Major_Period;

         Event.Set_Handler (Next, Handler'Access);

      end Handler;

   end Poller;

   ---------------
   -- Idle_Task --
   ---------------

   task body Idle_Task is
   begin
      loop
         null;
      end loop;
   end Idle_Task;

end Execution_Time_Poller;
