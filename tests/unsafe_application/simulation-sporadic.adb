with Ada.Real_Time, Utilities, GNAT.IO;
use Ada.Real_Time, Utilities, GNAT.IO;

package body Simulation.Sporadic is

   ---------------
   -- Constants --
   ---------------

   Chunck   : constant := 100;
   Recovery : constant := 200;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (S : in out Simulated_Sporadic) is
   begin

      Reset (S.Gen, 2 * S.T + 3 * S.C);

      S.MIT      := Microseconds (S.T);
      S.Recovery := Microseconds (Recovery);
      S.Budget   := Microseconds (S.C) - S.Recovery;

      S.Overruns := 0;

   end Initialize;

   ----------
   -- Code --
   ----------

   procedure Code (S : in out Simulated_Sporadic) is
      W : Integer;
   begin

      S.Timeout := False;

      if Random (S.Gen'Access) < 50 then
         W := S.C - S.C / 4;
      else
         W := S.C + S.C / 4;
      end if;

      while W > 0 loop

         Busy_Wait (Integer'Min (W, Chunck));

         exit when S.Timeout;

         W := W - Chunck;

      end loop;

   end Code;

   -------------------
   -- Deadline_Miss --
   -------------------

   procedure Deadline_Miss (S : in out Simulated_Sporadic) is
   begin
      raise Deadline_Error with S.N & " missed deadline!";
   end Deadline_Miss;

end Simulation.Sporadic;
