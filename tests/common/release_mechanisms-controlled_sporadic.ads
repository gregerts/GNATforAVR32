with Ada.Interrupts, Ada.Real_Time.Timing_Events, Ada.Execution_Time.Timers,
  System, Task_States.Sporadic, Interrupt_States, Release_Mechanisms;
use Ada.Interrupts, Ada.Real_Time.Timing_Events, Ada.Execution_Time.Timers,
  System, Task_States.Sporadic, Interrupt_States, Release_Mechanisms;

package Release_Mechanisms.Controlled_Sporadic is

   type Controlled_Sporadic_Release (S : Any_Sporadic_Task_State)
      is limited new Open_Release_Mechanism with private;

   procedure Wait_For_Next_Release (R : in out Controlled_Sporadic_Release);

   procedure Release (R : in out Controlled_Sporadic_Release);

private

   protected type Mechanism (S : Any_Sporadic_Task_State) is

      procedure Initialize;
      procedure Release;
      entry Wait;

      pragma Priority (Any_Priority'Last);

   private

      procedure Release_Allowed (TE : in out Timing_Event);
      procedure Overran (TM : in out Timer);

      Execution_Timer : access Timer;
      Event_MIT : Timing_Event;
      Released : Boolean := False;
      Allowed : Boolean := False;
      Open : Boolean := False;

   end Mechanism;

   type Controlled_Sporadic_Release (S : Any_Sporadic_Task_State)
      is limited new Open_Release_Mechanism with
      record
        M : Mechanism (S);
        First : Boolean := True;
      end record;

end Release_Mechanisms.Controlled_Sporadic;
