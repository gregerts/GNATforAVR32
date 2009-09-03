with Utilities, GNAT.IO;
use Utilities, GNAT.IO;

package body Simulation.Interrupt is

   -------------
   -- Handler --
   -------------

   procedure Handler (S : in out Simulated_Interrupt) is
   begin

      if not S.Burst then
         S.Clear;
      end if;

      S.Count := S.Count + 1;

      if S.Count mod 10000 = 4000 or S.Count mod 10000 = 6000 then
         S.Burst := not S.Burst;
         GNAT.IO.Put ('!');
      end if;

      if S.Count mod 10 = 0 then
         GNAT.IO.Put ('.');
      end if;

      Busy_Wait (100);

   end Handler;

   ------------
   -- Enable --
   ------------

   procedure Enable (S : in out Simulated_Interrupt) is
   begin
      External_Interrupt (S).Enable;
      GNAT.IO.Put ('E');
   end Enable;

   -------------
   -- Disable --
   -------------

   procedure Disable (S : in out Simulated_Interrupt) is
   begin
      External_Interrupt (S).Disable;
      GNAT.IO.Put ('D');
   end Disable;

end Simulation.Interrupt;
