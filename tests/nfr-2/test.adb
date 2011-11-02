with Ada.Unchecked_Conversion, System, Ada.Real_Time, Ada.Execution_Time,
  Utilities, GNAT.IO;
use System, Ada.Real_Time, Utilities, GNAT.IO;

package body Test is

   package AET renames Ada.Execution_Time;

   D : constant := 1000;

   type Data is mod 2 ** 64;
   for Data'Size use 64;

   R : array (1 .. 4) of Data;

   function To_Data is new Ada.Unchecked_Conversion (Time, Data);
   function To_Data is new Ada.Unchecked_Conversion (AET.CPU_Time, Data);

   procedure Put_Data is new Put_Hex (Data);

   task Sporadic is
      pragma Priority (Priority'Last);
   end Sporadic;

   task body Sporadic is
      Next : Time := Clock;
      C : Data;
   begin

      New_Line;
      Put_Line ("SYNC");
      Put (R'Length + 1);
      New_Line;

      loop

         delay until Next;

         R (1) := To_Data (Clock);
	 R (2) := To_Data (Clock);
         R (3) := To_Data (AET.Clock (Sporadic'Identity));
         R (4) := To_Data (AET.Clock (Sporadic'Identity));

         pragma Assert (R (2) > R (1) and R (4) > R (3));

         C := 0;

         for I in R'Range loop
            C := C xor R (I);
            Put_Data (R (I));
            Put (':');
         end loop;

         Put_Data (C);
	 New_Line;

         Next := Next + Microseconds (D);

      end loop;

   end Sporadic;

   procedure Run is
   begin
      delay until Time_Last;
   end Run;

end Test;
