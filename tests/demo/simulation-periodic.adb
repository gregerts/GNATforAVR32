with Ada.Real_Time, GNAT.IO, Utilities;
use Ada.Real_Time, Utilities;

package body Simulation.Periodic is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (S : in out Simulated_Periodic) is
   begin
      S.Period := Milliseconds (S.T);
      S.Budget := Milliseconds (S.C);
   end Initialize;

   ----------
   -- Code --
   ----------

   procedure Code (S : in out Simulated_Periodic) is
   begin
      Busy_Wait (S.C * 950);
   end Code;

   -------------------
   -- Deadline_Miss --
   -------------------

   procedure Deadline_Miss (S : in out Simulated_Periodic) is
   begin
      raise Deadline_Error with "Deadline missed for task " & S.Name;
   end Deadline_Miss;

   -------------
   -- Overrun --
   -------------

   procedure Overrun (S : in out Simulated_Periodic) is
   begin
      raise Overrun_Error with "Overrun for task " & S.Name;
   end Overrun;

end Simulation.Periodic;
