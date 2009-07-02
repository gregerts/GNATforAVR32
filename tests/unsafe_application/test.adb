with Simulation.Periodic, Simulation.Interrupt, Simulation.Sporadic,
  Release_Mechanisms.Sporadic, Release_Mechanisms.Periodic,
  Real_Time_Tasks, Interrupt_Handlers, External_Interrupts,
  Ada.Real_Time, Ada.Interrupts.Names, Ada.Execution_Time.Timers,
  Ada.Task_Identification, Execution_Time_Poller, GPIO_Controller, Error;

use Simulation.Periodic, Simulation.Interrupt, Simulation.Sporadic,
  Release_Mechanisms.Sporadic, Release_Mechanisms.Periodic,
  Real_Time_Tasks, Interrupt_Handlers, Ada.Real_Time,
  Ada.Interrupts.Names, Ada.Execution_Time.Timers,
  Ada.Task_Identification, GPIO_Controller;

package body Test is

   package ETP renames Execution_Time_Poller;

   --------------
   -- Periodic --
   --------------

   S_A : aliased Simulated_Periodic  ('A', 25_000,  2_000);
   S_B : aliased Simulated_Periodic  ('B', 50_000,  5_000);
   S_C : aliased Simulated_Periodic  ('C', 100_000, 20_000);
   S_D : aliased Simulated_Periodic  ('D', 200_000, 20_000);

   R_A : aliased Periodic_Release (S_A'Access);
   R_B : aliased Periodic_Release (S_B'Access);
   R_C : aliased Periodic_Release (S_C'Access);
   R_D : aliased Periodic_Release (S_D'Access);

   --------------
   -- Sporadic --
   --------------

   S_S : aliased Simulated_Sporadic ('S', 25_000, 10_000);

   R_S : aliased Sporadic_Release (S_S'Access);

   -----------
   -- Tasks --
   -----------

   T_S : Real_Time_Task (200, S_S'Access, R_S'Access);
   T_A : Real_Time_Task (190, S_A'Access, R_A'Access);
   T_B : Real_Time_Task (180, S_B'Access, R_B'Access);
   T_C : Real_Time_Task (170, S_C'Access, R_C'Access);
   T_D : Real_Time_Task (160, S_D'Access, R_D'Access);

   ---------------
   -- Interrupt --
   ---------------

   S_I : aliased Simulated_Interrupt (EIM_5, 250, 5, R_S'Access);

   H_I : Interrupt_Handler (EIM_5, EIM_5_Priority, S_I'Access);

   ---------
   -- Run --
   ---------

   procedure Run is
   begin
      ETP.Run;
   end Run;

begin

   --  Setup and enable external interrupt

   Configure_Peripheral (Port_A, 4, Peripheral_B);

   S_I.Initialize (External_Interrupts.Falling);
   S_I.Enable;

   --  Register tasks and initialize Poller

   ETP.Initialize (6, Microseconds (S_D.T));

   ETP.Register (T_S'Identity);
   ETP.Register (T_A'Identity);
   ETP.Register (T_B'Identity);
   ETP.Register (T_C'Identity);
   ETP.Register (T_D'Identity);
   ETP.Register (Current_Task);

end Test;
