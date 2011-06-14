with System, Ada.Real_Time.Timing_Events, Utilities,
  Random_Time, GNAT.IO;
use System, Ada.Real_Time, Ada.Real_Time.Timing_Events, Utilities,
  Random_Time, GNAT.IO;

package body Test is

   procedure Put is new Put_Hex (Integer);
   procedure Put is new Put_Hex (Time);
   
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
      TA, TB : Time;
   begin

      New_Line;
      Put_Line ("SYNC");
      Put (2);
      New_Line;

      Initialize (Gen, Microseconds (100), Microseconds (200));
      Reset (Gen, 43);
      
      TE.Set_Handler (Random (Gen'Access), Interrupter.Handler'Access);

      loop
	 TA := Clock;
	 TB := Clock;

	 pragma Assert (TA < TB);

	 Put (TA);
	 Put (':');
	 Put (TB);
	 New_Line;
	 
      end loop;

   end Run;

end Test;
