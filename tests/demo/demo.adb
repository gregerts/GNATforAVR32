with Simulation.Periodic, Simulation.Interrupt,
  Release_Mechanisms.Controlled_Periodic,
  Real_Time_Tasks, Interrupt_Handlers,
  Interrupt_Servers.Deferrable, External_Interrupts,
  Ada.Real_Time, Ada.Interrupts.Names,
  GPIO_Controller, GNAT.IO, Error;

use Simulation.Periodic, Simulation.Interrupt,
  Release_Mechanisms.Controlled_Periodic,
  Real_Time_Tasks, Interrupt_Handlers,
  Interrupt_Servers, Interrupt_Servers.Deferrable,
  Ada.Real_Time, Ada.Interrupts.Names,
  GPIO_Controller, GNAT.IO;

package body Demo is

   -----------
   -- Tasks --
   -----------

   S_A : aliased Simulated_Periodic ( 50, 10, 'A');
   S_B : aliased Simulated_Periodic (100, 40, 'B');

   R_A : aliased Controlled_Periodic_Release (S_A'Access);
   R_B : aliased Controlled_Periodic_Release (S_B'Access);

   T_A : Real_Time_Task (190, S_A'Access, R_A'Access);
   T_B : Real_Time_Task (180, S_B'Access, R_B'Access);

   ----------------
   -- Interrupts --
   ----------------

   S_I : aliased Simulated_Interrupt (EIM_5);

   H_I : Interrupt_Handler (EIM_5, EIM_5_Priority, S_I'Access);

   P_I : aliased Interrupt_Server_Parameters :=
     (Pri    => EIM_5_Priority,
      Period => Milliseconds (50),
      Budget => Milliseconds (5));

   E_I : Deferrable_Interrupt_Server (P_I'Access);

   Use_Interrupt_Control : constant Boolean := True;

begin

   New_Line;
   New_Line;

   --  Configure external interrupt pin

   Configure_Peripheral (Port_A, 4, Peripheral_B);

   -- Setup and register external interrupt

   S_I.Initialize (External_Interrupts.Falling);

   if Use_Interrupt_Control then
      E_I.Register (S_I'Access);
   else
      S_I.Enable;
   end if;

end Demo;
