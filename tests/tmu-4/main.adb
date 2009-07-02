with GNAT.IO;
with Ada.Execution_Time;
with Utilities;
with Error;

use GNAT.IO;
use Ada.Execution_Time;
use Utilities;

procedure Main is

   procedure Put is new Put_Hex (CPU_Time);

   TA, TB : CPU_Time;

begin

   New_Line;
   Put_Line ("SYNC");

   loop

      TA := Clock;
      Busy_Wait (50_000);
      TB := Clock;

      Put (TA);
      Put (':');
      Put (TB);

      New_Line;

   end loop;

end Main;
