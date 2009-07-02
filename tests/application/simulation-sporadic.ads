with Task_States.Sporadic, Percent_Random;
use Task_States.Sporadic, Percent_Random;

package Simulation.Sporadic is

   type Simulated_Sporadic (T, C : Natural) is
     new Sporadic_Task_State with
      record
         Gen     : aliased Generator;
         Timeout : Boolean;
         pragma Atomic (Timeout);
      end record;

   procedure Initialize    (S : in out Simulated_Sporadic);
   procedure Code          (S : in out Simulated_Sporadic);
   procedure Deadline_Miss (S : in out Simulated_Sporadic);
   procedure Overrun       (S : in out Simulated_Sporadic);

end Simulation.Sporadic;

