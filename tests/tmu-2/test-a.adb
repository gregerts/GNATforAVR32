with Ada.Real_Time;
with Ada.Execution_Time;
with GNAT.IO;
with Ada.Task_Identification;
with Short_Random;

use Ada.Real_Time;
use Ada.Execution_Time;
use Ada.Task_Identification;
use Short_Random;

package body Test.A is

   -------------
   -- Manager --
   -------------

   protected body Manager is

      -------------
      -- Handler --
      -------------

      procedure Handler (TM : in out Timer) is
      begin
         pragma Assert (TM.Current_Handler = null
                          and
                        TM.Time_Remaining = Time_Span_Zero);

         Count := Count + 1;

         if Count mod 100 = 0 then
            GNAT.IO.Put ('A');
         end if;

      end Handler;

   end Manager;

   ------------
   -- Worker --
   ------------

   task body Worker is

      Id : aliased constant Task_Id := Worker'Identity;
      TM : Timer (Id'Access);

      Last : CPU_Time := CPU_Time_First;
      Next : Time     := Time_First + Milliseconds (100);

      Gen : aliased Generator;
      X   : Integer;

      Cancelled : Boolean;

   begin

      GNAT.IO.New_Line;

      Reset (Gen, 13);

      loop

         delay until Next;

         declare
            Now : constant CPU_Time := Clock (Id);
         begin
            pragma Assert (Last < Now);

            Last := Now;
         end;

         X := (2000 * Natural (Random (Gen'Access))) / Distribution'Last;

         TM.Set_Handler (Last + Microseconds (X), Manager.Handler'Access);

         Busy_Wait (500);

         TM.Cancel_Handler (Cancelled);

         Next := Next + Milliseconds (1);

      end loop;

   end Worker;

end Test.A;
