with Ada.Real_Time, Utilities;
use Ada.Real_Time, Utilities;

package body Simulation.Aperiodic is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (S : in out Simulated_Aperiodic) is
   begin
      Reset (S.Gen, 3 * S.C);
      S.Replinish_Period := Milliseconds (S.T);
      S.Recovery := Microseconds (250);
      S.Budget := Milliseconds (S.C) - S.Recovery;
   end Initialize;

   ----------
   -- Code --
   ----------

   procedure Code (S : in out Simulated_Aperiodic) is
      W : constant Integer := (10 * S.C * Random (S.Gen'Access));
   begin
      for I in 1 .. W loop
         Busy_Wait (100);
         if S.Timeout then
            Suspend_Until_True (S.Suspension);
         end if;
      end loop;
   end Code;

   -------------
   -- Overrun --
   -------------

   procedure Overrun (S : in out Simulated_Aperiodic) is
   begin
      raise Overrun_Error;
   end Overrun;

   ----------
   -- Hold --
   ----------

   procedure Hold (S : in out Simulated_Aperiodic) is
   begin
      S.Timeout := True;
      Set_False (S.Suspension);
   end Suspend;

   --------------
   -- Continue --
   --------------

   procedure Continue (S : in out Simulated_Aperiodic) is
   begin
      S.Timeout := False;
      Set_True (S.Suspension);
   end Continue;

end Simulation.Aperiodic;
