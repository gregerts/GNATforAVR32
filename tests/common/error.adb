with GNAT.IO;
with GPIO_Controller;
with System.Machine_Code;
with Utilities;

use GPIO_Controller;
use System.Machine_Code;
use Utilities;

package body Error is

   -------------------------
   -- Last_Chance_Handler --
   -------------------------

   procedure Last_Chance_Handler (Message : access String) is
   begin

      --  Mask interrupts (AVR32 specific)

      Asm ("ssrf    16"     & ASCII.LF & ASCII.HT &
           "nop"            & ASCII.LF & ASCII.HT &
           "nop"            & ASCII.LF & ASCII.HT &
           "nop"            & ASCII.LF & ASCII.HT &
           "nop",
           Volatile => True);

      --  Set LED 6 to RED to indicate error.

      Clear_Pin (Port_B, 21);
      Set_Pin   (Port_B, 22);

      --  Output error message

      loop
     
 	 GNAT.IO.New_Line;

	 GNAT.IO.Put ("Error: ");
	 GNAT.IO.Put (Message.all);

	 GNAT.IO.New_Line;

	 for I in 1 .. 120 loop
	    Busy_Wait (500_000);
	    Toggle_Pin (Port_B, 21);
	 end loop;

      end loop;

   end Last_Chance_Handler;

begin

   --  Configure LED 6 as GPIO pin.

   Configure_GPIO (Port_B, Range_To_Mask (21, 22), True);

   --  Set LED 6 to GREEN to indicate normal operation.

   Set_Pin (Port_B, 21);

end Error;
