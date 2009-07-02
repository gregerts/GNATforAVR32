with Short_Random;
with Ada.Execution_Time.Timers;

use Ada.Execution_Time.Timers;
use Short_Random;

package Test.B is

   --  This package tests the timer of another task

   task Worker is
      pragma Priority (10);
      pragma Storage_Size (Size);
   end Worker;

   protected Manager is
      procedure Initialize (TM : in out Timer);
      procedure Handler_1  (TM : in out Timer);
      procedure Handler_2  (TM : in out Timer);

      pragma Priority (Min_Handler_Ceiling);
   private
      Gen   : aliased Generator;
      Count : Natural := 0;
   end Manager;

end Test.B;
