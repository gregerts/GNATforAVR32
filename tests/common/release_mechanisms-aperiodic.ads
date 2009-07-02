with Ada.Synchronous_Task_Control;
use Ada.Synchronous_Task_Control;

package Release_Mechanisms.Aperiodic is

   type Aperiodic_Release is limited
     new Open_Release_Mechanism with private;

   procedure Wait_For_Next_Release (S : in out Aperiodic_Release);

   procedure Release (S : in out Aperiodic_Release);

private

   type Aperiodic_Release is limited
     new Open_Release_Mechanism with
      record
        SO : Suspension_Object;
      end record;

end Release_Mechanisms.Aperiodic;
