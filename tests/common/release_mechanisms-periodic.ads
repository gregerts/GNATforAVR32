------------------------------------------------------------------
--  Adapted from "Concurrent and Real-Time Programming in Ada"  --
--               by Alan Burns and Andy Wellings.               --
------------------------------------------------------------------

with Ada.Real_Time, Task_States.Periodic, Epoch_Support;
use Ada.Real_Time, Task_States.Periodic, Epoch_Support;

package Release_Mechanisms.Periodic is

   type Periodic_Release (S : Any_Periodic_Task_State) is
     new Release_Mechanism with private;

   procedure Wait_For_Next_Release (R : in out Periodic_Release);

private

   type Periodic_Release (S : Any_Periodic_Task_State) is
     new Release_Mechanism with
      record
         Next : Time := Epoch;
      end record;

end Release_Mechanisms.Periodic;
