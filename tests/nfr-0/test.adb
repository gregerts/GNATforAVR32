with System, Ada.Real_Time, Ada.Unchecked_Conversion, Ada.Execution_Time.Timers,
  Ada.Task_Identification, Utilities, GNAT.IO;
use System, Ada.Real_Time, Ada.Execution_Time, Ada.Execution_Time.Timers,
  Ada.Task_Identification, Utilities, GNAT.IO;

package body Test is

   type Data is mod 2 ** 64;
   for Data'Size use 64;

   function To_Data is new Ada.Unchecked_Conversion (CPU_Time, Data);
   procedure Put_Data is new Put_Hex (Data);

   task Runner is
      pragma Priority (Priority'Last);
   end Runner;

   protected Interrupter is
      procedure Handler (TM : in out Timer);
      pragma Priority (Any_Priority'Last);
   end Interrupter;

   T  : aliased constant Task_Id := Runner'Identity;
   TM : Timer (T'Access);
   DT : constant := 10_000;

   task body Runner is
      A, B : Data;
   begin

      New_Line;
      Put_Line ("SYNC");
      Put_Data (3);
      New_Line;

      loop

         if TM.Current_Handler = null then
            TM.Set_Handler (Microseconds (2 * DT), Interrupter.Handler'Access);
         end if;

         A := To_Data (Clock (T));
         Busy_Wait (DT);
	 B := To_Data (Clock (T));

	 pragma Assert (A < B);

	 Put_Data (A);
	 Put (':');
	 Put_Data (B);
	 Put (':');
	 Put_Data (A xor B);
	 New_Line;

      end loop;

   end Runner;

   protected body Interrupter is

      procedure Handler (TM : in out Timer) is
      begin
         null;
      end Handler;

   end Interrupter;

   procedure Run is
   begin
      delay until Time_Last;
   end Run;

end Test;
