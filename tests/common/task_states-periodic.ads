------------------------------------------------------------------
--  Adapted from "Concurrent and Real-Time Programming in Ada"  --
--               by Alan Burns and Andy Wellings.               --
------------------------------------------------------------------

package Task_States.Periodic is

   type Periodic_Task_State is abstract new Task_State with
      record
         Period : Time_Span;
      end record;

   type Any_Periodic_Task_State is access all Periodic_Task_State'Class;

end Task_States.Periodic;
