with System, Ada.Real_Time, Utilities, GNAT.IO;
use System, Ada.Real_Time, Utilities, GNAT.IO;

package body Test is

   procedure Put is new Put_Hex (Time);

   protected Timed_SO is
      procedure Release;
      entry Suspend (R : out Time);
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

      entry Suspend (R : out Time) when Open is
      begin
	 Open := False;
	 R := Release_Time;
      end Suspend;

   end Timed_SO;

   task body Sporadic is
      C, R : Time;
   begin
      loop

	 Timed_SO.Suspend (R);
	 C := Clock;

	 pragma Assert (C > R);

	 Put (R);
	 Put (':');
	 Put (C);
	 New_Line;

      end loop;
   end Sporadic;

   procedure Run is
   begin

      New_Line;
      Put_Line ("SYNC");

      loop
	 Timed_SO.Release;
      end loop;

   end Run;

end Test;
