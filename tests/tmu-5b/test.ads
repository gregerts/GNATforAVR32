with System;
with Ada.Real_Time;
with Ada.Execution_Time.Timers;

use Ada.Real_Time;
use Ada.Execution_Time.Timers;

package Test is

   Period : constant Time_Span := Microseconds (524_288);

   protected P is

      pragma Priority (System.Any_Priority'Last);

      procedure Handler (TM : in out Timer);

      procedure Signal;

      entry Wait;

      function Next_A return Time;

      function Next_B return Time;

   private
      Open : Boolean := False;
      Long : Boolean := False;
      Next : Time    := Time_First + Milliseconds (1);
   end P;

   task A is
      pragma Priority (100);
   end A;

   task B is
      pragma Priority (50);
   end B;

end Test;

