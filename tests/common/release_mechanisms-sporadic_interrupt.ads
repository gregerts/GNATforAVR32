with Ada.Interrupts, Ada.Real_Time.Timing_Events, Ada.Execution_Time.Timers,
  System, Task_States.Sporadic, Interrupt_States, Release_Mechanisms;
use Ada.Interrupts, Ada.Real_Time.Timing_Events, Ada.Execution_Time.Timers,
  System, Task_States.Sporadic, Interrupt_States, Release_Mechanisms;

package Release_Mechanisms.Sporadic_Interrupt is

   type Interrupt_Release
     (Id : Interrupt_Id;
      S  : Any_Sporadic_Task_State)
      is limited new Release_Mechanism with private;

   procedure Wait_For_Next_Release (R : in out Interrupt_Release);

private

   protected type Mechanism
     (Id : Interrupt_Id;
      S  : Any_Sporadic_Task_State) is

      procedure Initialize;
      entry Wait;

      pragma Priority (Any_Priority'Last);

   private

      procedure Release_Allowed (TE : in out Timing_Event);
      procedure Overran (TM : in out Timer);
      procedure Release;

      pragma Attach_Handler (Release, Id);

      Execution_Timer : access Timer;
      Event_MIT       : Timing_Event;

      Open     : Boolean := False;
      Released : Boolean := False;
      Allowed  : Boolean := False;

   end Mechanism;

   type Interrupt_Release
     (Id : Interrupt_Id;
      S  : Any_Sporadic_Task_State)
      is limited new Release_Mechanism with
      record
        M : Mechanism (Id, S);
        First : Boolean := True;
      end record;

end Release_Mechanisms.Sporadic_Interrupt;
