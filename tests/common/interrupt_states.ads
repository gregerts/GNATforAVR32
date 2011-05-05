with Ada.Interrupts;
use Ada.Interrupts;

package Interrupt_States is

   type Interrupt_State is limited interface;

   procedure Handler (S : in out Interrupt_State) is abstract;
   procedure Enable  (S : in out Interrupt_State) is abstract;
   procedure Disable (S : in out Interrupt_State) is abstract;

   function Identity (S : Interrupt_State) return Interrupt_ID is abstract;

   type Any_Interrupt_State is access all Interrupt_State'Class;

end Interrupt_States;
