with Ada.Real_Time, System, Interrupt_States;
use Ada.Real_Time, System, Interrupt_States;

package Interrupt_Servers is

   type Interrupt_Server_Parameters is
      record
         Pri : Interrupt_Priority;
         Budget : Time_Span;
         Period : Time_Span;
      end record;

   type Interrupt_Server is limited interface;

   procedure Register
     (S : in out Interrupt_Server;
      I : Any_Interrupt_State) is abstract;

   type Any_Interrupt_Server is access all Interrupt_Server;

end Interrupt_Servers;
