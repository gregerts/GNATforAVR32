with Utilities, GNAT.IO;
use Utilities, GNAT.IO;

package body Simulation.Interrupt is

   -------------
   -- Handler --
   -------------

   procedure Handler (S : in out Simulated_Interrupt) is
   begin

      S.Clear;
      Busy_Wait (S.C);
      S.Count := S.Count + 1;

      if S.Count mod S.N = 0 then
         S.R.Release;
      end if;

   end Handler;

end Simulation.Interrupt;
