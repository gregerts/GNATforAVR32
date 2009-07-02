with Ada.Execution_Time.Timers;
use Ada.Execution_Time.Timers;

package Test.A is

   --  This package tests the own timer of a task

   protected Manager is
      procedure Handler (TM : in out Timer);
      pragma Priority (Min_Handler_Ceiling);
   private
      Count : Natural := 0;
   end Manager;

   task Worker is
      pragma Priority (100);
      pragma Storage_Size (Size);
   end Worker;

end Test.A;
