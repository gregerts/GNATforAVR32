with Ada.Unchecked_Conversion, System, Ada.Real_Time, Utilities, GNAT.IO;
use System, Ada.Real_Time, Utilities, GNAT.IO;

package body Test is

   type Data is mod 2 ** 64;
   for Data'Size use 64;
   
   function To_Data is new Ada.Unchecked_Conversion (Time, Data);
   
   procedure Put_Data is new Put_Hex (Data);

   protected Timed_SO is
      procedure Release;
      entry Suspend (D : out Data);
   private
      Open : Boolean := False;
      Release_Time : Time;
   end Timed_SO;

   task Sporadic is
      pragma Priority (Priority'Last);
   end Sporadic;
   
   protected body Timed_SO is
      
      procedure Release is
      begin
	 Open := True;
	 Release_Time := Clock;
      end Release;

      entry Suspend (D : out Data) when Open is
      begin
	 Open := False;
	 D := To_Data (Release_Time);
      end Suspend;

   end Timed_SO;

   task body Sporadic is
      A, B : Data;
   begin
      loop

	 Timed_SO.Suspend (A);
	 B := To_Data (Clock);

	 pragma Assert (B > A);

	 Put_Data (A);
	 Put (':');
	 Put_Data (B);
	 Put (':');
	 Put_Data (A xor B);
	 New_Line;

      end loop;
   end Sporadic;

   procedure Run is
      Next : Time := Clock;
   begin

      New_Line;
      Put_Line ("SYNC");
      Put (3);
      New_Line;

      loop
         delay until Next;
	 Timed_SO.Release;
         Next := Next + Milliseconds (10);
      end loop;

   end Run;

end Test;
