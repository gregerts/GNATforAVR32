with GNAT.IO;
with GPIO_Controller;
with System.Machine_Code;

use GPIO_Controller;
use System.Machine_Code;

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

      Set_Pin   (Port_B, 21);
      Clear_Pin (Port_B, 22);

      --  Output error message

      GNAT.IO.New_Line;

      GNAT.IO.Put ("Error: ");
      GNAT.IO.Put (Message.all);

      GNAT.IO.New_Line;

      --  Loop forever...

      loop
         null;
      end loop;

   end Last_Chance_Handler;

begin

   --  Configure LED 6 as GPIO pin.

   Configure_GPIO (Port_B, Range_To_Mask (21, 22));

   --  Set LED 6 to GREEN to indicate normal operation.

   Clear_Pin (Port_B, 21);
   Set_Pin   (Port_B, 22);

end Error;
