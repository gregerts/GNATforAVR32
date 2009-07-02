------------------------------------------------------------------
--  Adapted from "Concurrent and Real-Time Programming in Ada"  --
--               by Alan Burns and Andy Wellings.               --
------------------------------------------------------------------

package Task_States.Sporadic is

   type Sporadic_Task_State is abstract new Task_State with
      record
         MIT : Time_Span;
      end record;

   type Any_Sporadic_Task_State is access all Sporadic_Task_State'Class;

end Task_States.Sporadic;
