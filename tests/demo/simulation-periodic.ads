with Task_States.Periodic, Percent_Random;
use Task_States.Periodic, Percent_Random;

package Simulation.Periodic is

   type Simulated_Periodic
     (T, C : Natural;
      Name : Character) is
     new Periodic_Task_State with
      record
         Gen     : aliased Generator;
         Timeout : Boolean;
         pragma Atomic (Timeout);
      end record;

   procedure Initialize    (S : in out Simulated_Periodic);
   procedure Code          (S : in out Simulated_Periodic);
   procedure Deadline_Miss (S : in out Simulated_Periodic);
   procedure Overrun       (S : in out Simulated_Periodic);

end Simulation.Periodic;
