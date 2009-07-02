------------------------------------------------------------------
--  Adapted from "Concurrent and Real-Time Programming in Ada"  --
--               by Alan Burns and Andy Wellings.               --
------------------------------------------------------------------

package Task_States.Aperiodic is

   type Aperiodic_Task_State is abstract new Task_State with
      record
         Replenish_Period : Time_Span := Time_Span_Last;
      end record;

   procedure Hold (S : in out Aperiodic_Task_State) is abstract;
   procedure Continue (S : in out Aperiodic_Task_State) is abstract;

   type Any_Aperiodic_Task_State is access all Aperiodic_Task_State'Class;

end Task_States.Aperiodic;
