with System, Ada.Real_Time.Timing_Events, Ada.Unchecked_Conversion,
  Utilities, Random_Time, GNAT.IO;
use System, Ada.Real_Time, Ada.Real_Time.Timing_Events,
  Utilities, Random_Time, GNAT.IO;

package body Test is

   type Data is mod 2 ** 64;
   for Data'Size use 64;
   
   function To_Data is new Ada.Unchecked_Conversion (Time, Data);
   
   procedure Put_Data is new Put_Hex (Data);
   
   TE : Timing_Event;
   Gen : aliased Generator;

   protected Interrupter is
      procedure Handler (Event : in out Timing_Event);
      pragma Priority (Any_Priority'Last);
   end Interrupter;

   protected body Interrupter is
      procedure Handler (Event : in out Timing_Event) is
      begin
	 Event.Set_Handler (Random (Gen'Access), Handler'Access);
      end Handler;
   end Interrupter;

   procedure Run is
      A, B : Data;
   begin

      New_Line;
      Put_Line ("SYNC");
      Put_Data (3);
      New_Line;

      Initialize (Gen, Microseconds (100), Microseconds (200));
      Reset (Gen, 43);
      
      TE.Set_Handler (Random (Gen'Access), Interrupter.Handler'Access);

      loop
	 A := To_Data (Clock);
	 B := To_Data (Clock);

	 pragma Assert (A < B);

	 Put_Data (A);
	 Put (':');
	 Put_Data (B);
	 Put (':');
	 Put_Data (A xor B);
	 New_Line;
	 
      end loop;

   end Run;

end Test;
