with Ada.Real_Time;
with Ada.Execution_Time;
with GNAT.IO;
with Ada.Task_Identification;

use Ada.Real_Time;
use Ada.Execution_Time;
use Ada.Task_Identification;

package body Test.B is

   -------------
   -- Manager --
   -------------

   protected body Manager is

      ----------------
      -- Initialize --
      ----------------

      procedure Initialize (TM : in out Timer) is
      begin
         Reset (Gen, 17);

         TM.Set_Handler (CPU_Time_First, Handler_1'Access);

      end Initialize;

      ---------------
      -- Handler_1 --
      ---------------

      procedure Handler_1 (TM : in out Timer) is
         X : Natural;
      begin

         pragma Assert (TM.Current_Handler = null);

         X := (2000 * Random (Gen'Access)) / Distribution'Last;

         TM.Set_Handler (Microseconds (X), Handler_2'Access);

         Count := Count + 1;

         if Count mod 100 = 0 then
            GNAT.IO.Put ('B');
         end if;

      end Handler_1;

      ---------------
      -- Handler_2 --
      ---------------

      procedure Handler_2 (TM : in out Timer) is
         X : Integer;
      begin

         pragma Assert (TM.Current_Handler = null);

         X := (2000 * Random (Gen'Access)) / Distribution'Last;

         TM.Set_Handler (Microseconds (X), Handler_1'Access);

      end Handler_2;

   end Manager;

   ------------
   -- Worker --
   ------------

   task body Worker is

      Id : aliased constant Task_Id := Current_Task;
      TM : Timer (Id'Access);

      Last : CPU_Time := CPU_Time_First;
   begin

      GNAT.IO.New_Line;

      Manager.Initialize (TM);

      loop

         declare
            Now : constant CPU_Time := Clock;
         begin

            pragma Assert (Now > Last
                             and
                           Now < Last + Seconds (1));
            Last := Now;
         end;

         declare
            Handler : constant Timer_Handler := TM.Current_Handler;
         begin

            pragma Assert (Handler = Manager.Handler_1'Access
                             or
                           Handler = Manager.Handler_2'Access);
            null;
         end;

      end loop;

   end Worker;

end Test.B;
