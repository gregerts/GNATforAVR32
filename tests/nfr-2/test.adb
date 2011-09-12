with Ada.Unchecked_Conversion, System, Ada.Real_Time, Utilities, GNAT.IO;
use System, Ada.Real_Time, Utilities, GNAT.IO;

package body Test is

   DT : constant Time_Span := Milliseconds (10);
   
   type Data is mod 2 ** 64;
   for Data'Size use 64;
   
   function To_Data is new Ada.Unchecked_Conversion (Time, Data);
   
   procedure Put_Data is new Put_Hex (Data);

   task Sporadic is
      pragma Priority (Priority'Last);
   end Sporadic;
   
   task body Sporadic is
      Next : Time := Clock + DT;
      A, B : Data;
   begin

      New_Line;
      Put_Line ("SYNC");
      Put (4);
      New_Line;

      loop

         delay until Next;
         
         A := To_Data (Clock);
	 B := To_Data (Clock);

         pragma Assert (B > A);
                 
         Put_Data (To_Data (Next));
         Put (':');
         Put_Data (A);
         Put (':');
         Put_Data (B);
         Put (':');
	 Put_Data (To_Data (Next) xor A xor B);
	 New_Line;

         Next := Next + DT;
         
      end loop;
      
   end Sporadic;

   procedure Run is
   begin
      loop
         Busy_Wait (10_000);
      end loop;
   end Run;

end Test;
