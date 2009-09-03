with Ada.Interrupts, Release_Mechanisms, External_Interrupts;
use Ada.Interrupts, Release_Mechanisms, External_Interrupts;

package Simulation.Interrupt is

   type Simulated_Interrupt (Id : External_Interrupt_Id) is
     new External_Interrupt (Id) with
      record
         Count : Natural := 0;
         Burst : Boolean := False;
      end record;

   procedure Handler (S : in out Simulated_Interrupt);

   overriding
   procedure Enable (S : in out Simulated_Interrupt);

   overriding
   procedure Disable (S : in out Simulated_Interrupt);

end Simulation.Interrupt;
