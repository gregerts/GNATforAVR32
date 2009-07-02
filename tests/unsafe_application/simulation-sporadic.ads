with Task_States.Sporadic, Percent_Random;
use Task_States.Sporadic, Percent_Random;

package Simulation.Sporadic is

   type Simulated_Sporadic
     (N    : Character;
      T, C : Natural)
      is new Sporadic_Task_State with
      record
         Gen      : aliased Generator;
         Overruns : Natural;
         Timeout  : Boolean;
         pragma Atomic (Timeout);
      end record;

   procedure Initialize    (S : in out Simulated_Sporadic);
   procedure Code          (S : in out Simulated_Sporadic);
   procedure Deadline_Miss (S : in out Simulated_Sporadic);

end Simulation.Sporadic;

