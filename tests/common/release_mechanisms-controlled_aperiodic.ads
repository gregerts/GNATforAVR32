with Task_States.Aperiodic, Ada.Execution_Time.Timers,
  Ada.Real_Time.Timing_Events, System;
use Task_States.Aperiodic, Ada.Execution_Time.Timers,
  Ada.Real_Time, Ada.Real_Time.Timing_Events, System;

package Release_Mechanisms.Controlled_Aperiodic is

   type Controlled_Aperiodic_Release (S : Any_Aperiodic_Task_State) is
      limited new Open_Release_Mechanism with private;

   procedure Wait_For_Next_Release (R : in out Controlled_Aperiodic_Release);

   procedure Release (R : in out Controlled_Aperiodic_Release);

private

   protected type Mechanism
     (S      : Any_Aperiodic_Task_State;
      Period : not null access Time_Span) is

      procedure Initialize;

      procedure Release;

      entry Wait;

      pragma Priority (Any_Priority'Last);

   private

      procedure Replenish (TE : in out Timing_Event);
      procedure Overran (TM : in out Timer);

      Execution_Timer : access Timer;
      Event_Replenish : Timing_Event;

      Next : Time;

      Suspended : Boolean := False;
      Released  : Boolean := False;
      Open      : Boolean := False;

   end Mechanism;

   type Controlled_Aperiodic_Release
     (S      : Any_Aperiodic_Task_State;
      Period : not null access Time_Span)
      is limited new Open_Release_Mechanism with
      record
        M : Mechanism (S, Period);
        First : Boolean := True;
      end record;

end Release_Mechanisms.Controlled_Aperiodic;
