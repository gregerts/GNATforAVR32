with GNAT.IO;
with Ada.Execution_Time;
with Ada.Task_Identification;
with Utilities;

use GNAT.IO;
use Ada.Execution_Time;
use Ada.Task_Identification;
use Utilities;

package body Test is

   procedure Put is new Put_Hex (CPU_Time);

   -------
   -- P --
   -------

   protected body P is

      -------------
      -- Handler --
      -------------


      procedure Handler (TM : in out Timer) is
      begin
         null;
      end Handler;

      ------------
      -- Signal --
      ------------

      procedure Signal is
      begin
         Open := True;
         Next := Next + Period;
         Long := not Long;
      end Signal;

      ----------
      -- Wait --
      ----------

      entry Wait when Open is
      begin
         Open := False;
      end Wait;

      ------------
      -- Next_A --
      ------------

      function Next_A return Time is
      begin
         if Long then
            return Next + Milliseconds (10);
         else
            return Next;
         end if;
      end Next_A;

      ------------
      -- Next_B --
      ------------

      function Next_B return Time is
      begin
         return Next;
      end Next_B;

   end P;

   -------
   -- A --
   -------

   task body A is
      TA, TB : CPU_Time;
   begin

      New_Line;
      Put_Line ("SYNC");

      loop

         delay until P.Next_A;

         TA := Clock;
         P.Signal;
         TB := Clock;

         Put (TA);
         Put (':');
         Put (TB);

         New_Line;

      end loop;

   end A;

   -------
   -- B --
   -------

   task body B is
      Self : aliased Task_Id := Current_Task;
      TM   : Timer (Self'Access);
   begin

      TM.Set_Handler (CPU_Time_Last, P.Handler'Access);

      loop
         delay until P.Next_B;
         P.Wait;
      end loop;

   end B;

end Test;
