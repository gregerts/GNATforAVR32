with System, Ada.Real_Time.Timing_Events, Utilities, GNAT.IO;
use System, Ada.Real_Time, Ada.Real_Time.Timing_Events, Utilities, GNAT.IO;

package body Test is

   procedure Put is new Put_Hex (Time);

   DT : constant Time_Span := Microseconds (100);
   TE : Timing_Event;

   protected Interrupter is
      procedure Handler (Event : in out Timing_Event);
      pragma Priority (Any_Priority'Last);
   end Interrupter;

   protected body Interrupter is
      procedure Handler (Event : in out Timing_Event) is
      begin
	 Event.Set_Handler (DT, Handler'Access);
      end Handler;
   end Interrupter;

   procedure Run is
      TA, TB : Time;
   begin

      New_Line;
      Put_Line ("SYNC");

      TE.Set_Handler (DT, Interrupter.Handler'Access);

      loop
	 TA := Clock;
	 TB := Clock;

	 pragma Assert (TA < TB);

	 Put (TA);
	 Put (':');
	 Put (TB);
	 New_Line;

	 Busy_Wait (50);
	 
      end loop;

   end Run;

end Test;
