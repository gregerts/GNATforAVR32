with Ada.Interrupts, Interrupt_States, System;
use Ada.Interrupts, Interrupt_States, System;

package Release_Mechanisms.Interrupt is
   
   type Interrupt_Release
     (I : Interrupt_Id;
      P : Interrupt_Priority;
      S : Any_Interrupt_State) is limited new Release_Mechanism with private;
   
   procedure Wait_For_Next_Release (R : in out Interrupt_Release);

private
   
   protected type Mechanism
     (I : Interrupt_Id;
      P : Interrupt_Priority;
      S : Any_Interrupt_State) is
      
      entry Wait;
      
   private
                  
      procedure Handler;
      
      pragma Attach_Handler (Handler, I);
      pragma Interrupt_Priority (P);
      
      Open : Boolean := False;
      
   end Mechanism;

   type Interrupt_Release
     (I : Interrupt_Id;
      P : Interrupt_Priority;
      S : Any_Interrupt_State)
      is limited new Release_Mechanism with
      record
        M : Mechanism (I, P, S);
      end record;
   
end Release_Mechanisms.Interrupt;

