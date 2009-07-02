with Ada.Interrupts, Release_Mechanisms, External_Interrupts;
use Ada.Interrupts, Release_Mechanisms, External_Interrupts;

package Simulation.Interrupt is

   type Simulated_Interrupt
     (Id : External_Interrupt_Id;
      C  : Natural;
      N  : Natural;
      R  : Any_Open_Release_Mechanism)
      is new External_Interrupt (Id) with
      record
         Count : Natural := 0;
         Overruns : Natural := 0;
      end record;

   procedure Handler (S : in out Simulated_Interrupt);

end Simulation.Interrupt;
