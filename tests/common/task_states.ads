------------------------------------------------------------------
--  Adapted from "Concurrent and Real-Time Programming in Ada"  --
--               by Alan Burns and Andy Wellings.               --
------------------------------------------------------------------

with Ada.Real_Time, Ada.Task_Identification;
use Ada.Real_Time, Ada.Task_Identification;

package Task_States is

   type Task_State is abstract tagged limited
      record
         Tid : aliased Task_Id := Null_Task_Id;
         Budget : Time_Span := Time_Span_Last;
         Recovery : Time_Span := Time_Span_Zero;
      end record;

   procedure Initialize (S : in out Task_State) is abstract;
   procedure Code (S : in out Task_State) is abstract;
   procedure Deadline_Miss (S : in out Task_State) is null;
   procedure Overrun (S : in out Task_State) is null;

   type Any_Task_State is access all Task_State'Class;

end Task_States;

