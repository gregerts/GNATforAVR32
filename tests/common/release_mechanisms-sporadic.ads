with Ada.Real_Time.Timing_Events, Task_States.Sporadic, System;
use Ada.Real_Time.Timing_Events, Task_States.Sporadic, System;

package Release_Mechanisms.Sporadic is

   type Sporadic_Release (S : Any_Sporadic_Task_State)
      is limited new Open_Release_Mechanism with private;

   procedure Wait_For_Next_Release (R : in out Sporadic_Release);

   procedure Release (R : in out Sporadic_Release);

private

   protected type Mechanism (S : Any_Sporadic_Task_State) is

      procedure Initialize;

      procedure Release;

      entry Wait;

      pragma Priority (Any_Priority'Last);

   private

      procedure Release_Allowed (TE : in out Timing_Event);

      Event_MIT : Timing_Event;

      Open     : Boolean := False;
      Released : Boolean := False;
      Allowed  : Boolean := False;

   end Mechanism;

   type Sporadic_Release (S : Any_Sporadic_Task_State) is limited
     new Open_Release_Mechanism with
      record
        M : aliased Mechanism (S);
        First     : Boolean := True;
      end record;

end Release_Mechanisms.Sporadic;
