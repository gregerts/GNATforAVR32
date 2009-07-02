with Ada.Real_Time.Timing_Events, Ada.Execution_Time.Timers,
  Ada.Task_Identification, Task_States.Periodic, Epoch_Support, System;
use Ada.Real_Time, Ada.Real_Time.Timing_Events, Ada.Execution_Time.Timers,
  Ada.Task_Identification, Task_States.Periodic, Epoch_Support;

package Release_Mechanisms.Controlled_Periodic is

   type Controlled_Periodic_Release (S : Any_Periodic_Task_State) is
     limited new Release_Mechanism with private;

   procedure Wait_For_Next_Release (R : in out Controlled_Periodic_Release);

private

   protected type Mechanism (S : Any_Periodic_Task_State) is

      procedure Initialize;
      entry Wait;

      pragma Priority (System.Any_Priority'Last);

   private

      procedure Release (TE : in out Timing_Event);
      procedure Overran (TM : in out Timer);

      Execution_Timer : access Timer;
      Event_Period : Timing_Event;
      Next : Time := Epoch;
      Open : Boolean := False;

   end Mechanism;

   type Controlled_Periodic_Release (S : Any_Periodic_Task_State) is
      limited new Release_Mechanism with
      record
        M : Mechanism (S);
        First : Boolean := True;
      end record;

end Release_Mechanisms.Controlled_Periodic;
