with Simulation.Periodic, Simulation.Interrupt, Simulation.Sporadic,
  Release_Mechanisms.Controlled_Sporadic,
  Release_Mechanisms.Controlled_Periodic,
  Real_Time_Tasks, Interrupt_Handlers,
  Interrupt_Servers.Deferrable, External_Interrupts,
  Ada.Real_Time, Ada.Interrupts.Names, Ada.Execution_Time.Timers,
  Ada.Task_Identification, Execution_Time_Poller, GPIO_Controller, Error;

use Simulation.Periodic, Simulation.Interrupt, Simulation.Sporadic,
  Release_Mechanisms.Controlled_Sporadic,
  Release_Mechanisms.Controlled_Periodic,
  Real_Time_Tasks, Interrupt_Handlers,
  Interrupt_Servers, Interrupt_Servers.Deferrable,
  Ada.Real_Time, Ada.Interrupts.Names, Ada.Execution_Time.Timers,
  Ada.Task_Identification, GPIO_Controller;

package body Test is

   package ETP renames Execution_Time_Poller;

   -----------
   -- Tasks --
   -----------

   S_S : aliased Simulated_Sporadic ( 25, 10);
   S_A : aliased Simulated_Periodic ( 25,  2);
   S_B : aliased Simulated_Periodic ( 50,  5);
   S_C : aliased Simulated_Periodic (100, 20);
   S_D : aliased Simulated_Periodic (200, 20);

   R_S : aliased Controlled_Sporadic_Release (S_S'Access);
   R_A : aliased Controlled_Periodic_Release (S_A'Access);
   R_B : aliased Controlled_Periodic_Release (S_B'Access);
   R_C : aliased Controlled_Periodic_Release (S_C'Access);
   R_D : aliased Controlled_Periodic_Release (S_D'Access);

   T_S : Real_Time_Task (200, S_S'Access, R_S'Access);
   T_A : Real_Time_Task (190, S_A'Access, R_A'Access);
   T_B : Real_Time_Task (180, S_B'Access, R_B'Access);
   T_C : Real_Time_Task (170, S_C'Access, R_C'Access);
   T_D : Real_Time_Task (160, S_D'Access, R_D'Access);

   ----------------
   -- Interrupts --
   ----------------

   S_I : aliased Simulated_Interrupt (EIM_5, 250, 5, R_S'Access);

   H_I : Interrupt_Handler (EIM_5, EIM_5_Priority, S_I'Access);

   P_I : aliased Interrupt_Server_Parameters :=
     (State  => S_I'Access,
      Period => Milliseconds (25),
      Budget => Milliseconds (2));

   E_I : Deferrable_Interrupt_Server (P_I'Access);

   ---------
   -- Run --
   ---------

   procedure Run is
   begin
      ETP.Run (Milliseconds (200));
   end Run;

begin

   --  Configure external interrupt pin

   Configure_Peripheral (Port_A, 4, Peripheral_B);

   -- Initialize external interrupt and server

   S_I.Initialize (External_Interrupts.Falling);
   E_I.Initialize;

   -- Initialize poller and register tasks

   ETP.Register (T_S'Identity);
   ETP.Register (T_A'Identity);
   ETP.Register (T_B'Identity);
   ETP.Register (T_C'Identity);
   ETP.Register (T_D'Identity);
   ETP.Register (Current_Task);
   ETP.Register (COMPARE);
   ETP.Register (TC_1);
   ETP.Register (TC_2);
   ETP.Register (S_I.Identity);

end Test;
