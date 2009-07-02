with Ada.Real_Time, Utilities;
use Ada.Real_Time, Utilities;

package body Simulation.Periodic is

   ---------------
   -- Constants --
   ---------------

   Chunck   : constant := 100;
   Recovery : constant := 150;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (S : in out Simulated_Periodic) is
   begin

      Reset (S.Gen, 7 * S.T + 13 * S.C);

      S.Period   := Microseconds (S.T);
      S.Recovery := Microseconds (Recovery);
      S.Budget   := Microseconds (S.C) - S.Recovery;

      S.Overruns := 0;

   end Initialize;

   ----------
   -- Code --
   ----------

   procedure Code (S : in out Simulated_Periodic) is
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

   procedure Deadline_Miss (S : in out Simulated_Periodic) is
   begin
      raise Deadline_Error with S.N & " missed deadline!";
   end Deadline_Miss;

end Simulation.Periodic;
