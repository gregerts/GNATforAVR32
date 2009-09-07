with System, Ada.Real_Time, GPIO_Controller;
use System, Ada.Real_Time, GPIO_Controller;

package Test is

   ------------
   -- Worker --
   ------------

   task type Worker
     (Pin : Natural;
      Pri : Priority) is
      pragma Priority (Pri);
      pragma Storage_Size (4096);
   end Worker;

end Test;
