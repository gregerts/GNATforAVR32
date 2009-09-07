with GNAT.IO, Epoch_Support, Short_Random, Utilities, Error;
use Epoch_Support, Short_Random, Utilities;

package body Test is

   ------------
   -- Worker --
   ------------

   task body Worker is
      Gen  : aliased Generator;
      Next : Time := Epoch;
   begin

      Reset (Gen, Pri);

      loop

         delay until Next;

         Set_Pin (Port_B, Pin);

         Busy_Wait (Random (Gen'Access) / 2);

         Clear_Pin (Port_B, Pin);

         Next := Clock + Microseconds (4 * Random (Gen'Access));

      end loop;

   end Worker;

   --  Workers

   A : Worker (27,  104);
   B : Worker (28,  103);
   C : Worker (29,  102);
   D : Worker (30,  101);

begin

   --  Configure GPIO pins for LEDs

   Configure_GPIO (Port_B, Range_To_Mask (27, 30));

   Clear_Pins (Port_B, Range_To_Mask (27, 30));

end Test;
