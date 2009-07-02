with Ada.Real_Time;
use Ada.Real_Time;

package Epoch_Support is

   Epoch : constant Time := Time_First + Milliseconds (100);

end Epoch_Support;

