with Ada.Execution_Time, Ada.Execution_Time.Interrupts,
  Ada.Task_Identification, Ada.Real_Time.Timing_Events,
  GNAT.IO, System, Epoch_Support, Utilities;
use Ada.Execution_Time, Ada.Execution_Time.Interrupts,
  Ada.Task_Identification, Ada.Real_Time.Timing_Events,
  GNAT.IO, System, Epoch_Support, Utilities;

package body Execution_Time_Poller is

   type Interrupt_Array is array (Positive range <>) of Interrupt_ID;
   type Task_Array is array (Positive range <>) of Task_Id;
   type CPU_Time_Array is array (Positive range <>) of CPU_Time;

   procedure Put is new Put_Hex (Time);
   procedure Put is new Put_Hex (CPU_Time);

   protected Poller is

      procedure Start (P : Time_Span);
      entry Wait;

   private

      pragma Priority (Any_Priority'Last);

      procedure Handler (Event : in out Timing_Event);

      Period : Time_Span;

      Event : Timing_Event;
      Next  : Time;
      Done  : Boolean;

   end Poller;

   task Idle_Task is
      pragma Priority (Priority'First);
      pragma Storage_Size (256);
   end Idle_Task;

   ---------------
   -- Constants --
   ---------------

   Max_Interrupts : constant := 5;
   Max_Tasks      : constant := 10;

   ----------
   -- Data --
   ----------

   Interrupts     : Interrupt_Array (1 .. Max_Interrupts);
   Last_Interrupt : Natural := 0;

   Tasks     : Task_Array (1 .. Max_Tasks);
   Last_Task : Natural := 0;

   Polling_Time : Time;

   Interrupt_Time : CPU_Time_Array (1 .. Max_Interrupts);
   Task_Time      : CPU_Time_Array (1 .. Max_Tasks);
   Idle_Time      : CPU_Time;

   --------------
   -- Register --
   --------------

   procedure Register (T : Task_Id) is
   begin
      pragma Assert (Last_Task < Tasks'Length);

      Last_Task := Last_Task + 1;
      Tasks (Last_Task) := T;

   end Register;

   --------------
   -- Register --
   --------------

   procedure Register (I : Interrupt_ID) is
   begin
      pragma Assert (Last_Interrupt < Interrupts'Length);

      Last_Interrupt := Last_Interrupt + 1;
      Interrupts (Last_Interrupt) := I;

   end Register;

   ---------
   -- Run --
   ---------

   procedure Run (P : Time_Span) is
   begin

      Poller.Start (P);

      delay until Epoch;

      New_Line;
      Put_Line ("SYNC");

      loop

         Poller.Wait;

         Put (Polling_Time);
         Put (':');

         for I in 1 .. Last_Task loop
            Put (Task_Time (I));
            Put (':');
         end loop;

         for I in 1 .. Last_Interrupt loop
            Put (Interrupt_Time (I));
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

      procedure Start (P : Time_Span) is
      begin

         Period := P;
         Done   := False;
         Next   := Epoch_Support.Epoch + Period;

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

            for I in 1 .. Last_Interrupt loop
               Interrupt_Time (I) := Clock (Interrupts (I));
            end loop;

            for I in 1 .. Last_Task loop
               Task_Time (I) := Clock (Tasks (I));
            end loop;

            Idle_Time := Clock (Idle_Task'Identity);

            Done := True;

         end if;

         Next := Next + Period;

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
