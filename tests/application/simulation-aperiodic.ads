with Task_States.Aperiodic, Percent_Random, Ada.Synchronous_Task_Control;
use Task_States.Aperiodic, Percent_Random, Ada.Synchronous_Task_Control;

package Simulation.Aperiodic is

   type Simulated_Aperiodic (T, C : Natural) is
     new Aperiodic_Task_State with
      record
         Gen : aliased Generator;
         Suspension : Suspension_Object;
         Timeout : Boolean;
         pragma Atomic (Timeout);
      end record;

   procedure Initialize (S : in out Simulated_Aperiodic);
   procedure Code (S : in out Simulated_Aperiodic);
   procedure Overrun (S : in out Simulated_Aperiodic);
   procedure Hold (S : in out Simulated_Aperiodic);
   procedure Continue (S : in out Simulated_Aperiodic);

end Simulation.Aperiodic;
