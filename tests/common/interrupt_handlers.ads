with Ada.Interrupts, System, Interrupt_States, Release_Mechanisms;
use Ada.Interrupts, System, Interrupt_States, Release_Mechanisms ;

package Interrupt_Handlers is

   protected type Interrupt_Handler
     (Id  : Interrupt_Id;
      Pri : Interrupt_Priority;
      S   : not null Any_Interrupt_State) is
      pragma Interrupt_Priority (Pri);
   private
      procedure Handler;
      pragma Attach_Handler (Handler, Id);
   end Interrupt_Handler;

end Interrupt_Handlers;
