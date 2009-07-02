with Ada.Real_Time, Utilities;
use Ada.Real_Time, Utilities;

package body Simulation.Periodic is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (S : in out Simulated_Periodic) is
   begin
      Reset (S.Gen, 7 * S.T + 13 * S.C);
      S.Period   := Milliseconds (S.T);
      S.Recovery := Microseconds (250);
      S.Budget   := Milliseconds (S.C) - S.Recovery;
   end Initialize;

   ----------
   -- Code --
   ----------

   procedure Code (S : in out Simulated_Periodic) is
      W : Integer;
   begin

      S.Timeout := False;

      if Random (S.Gen'Access) < 50 then
         W := (30 * S.C) / 4;
      else
         W := (50 * S.C) / 4;
      end if;

      for I in 1 .. W loop
         Busy_Wait (100);
         exit when S.Timeout;
      end loop;

   end Code;

   -------------------
   -- Deadline_Miss --
   -------------------

   procedure Deadline_Miss (S : in out Simulated_Periodic) is
   begin
      raise Deadline_Error;
   end Deadline_Miss;

   -------------
   -- Overrun --
   -------------

   procedure Overrun (S : in out Simulated_Periodic) is
   begin
      if not S.Timeout then
         S.Timeout := True;
      else
         raise Overrun_Error;
      end if;
   end Overrun;

end Simulation.Periodic;
