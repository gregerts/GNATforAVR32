with Ada.Real_Time, Ada.Task_Identification, Epoch_Support, Utilities,
  Execution_Time_Poller;
use Ada.Real_Time, Ada.Task_Identification, Epoch_Support, Utilities;

package body Test is

   package ETP renames Execution_Time_Poller;



   --------------
   -- Periodic --
   --------------

   task body Periodic is
      Next : Time := Epoch;
   begin
      loop
         delay until Next;
         Busy_Wait (C);
         Next := Next + Microseconds (T);
      end loop;
   end Periodic;

   ---------
   -- Run --
   ---------

   procedure Run is
   begin
      ETP.Run;
   end Run;

begin

   ETP.Initialize (5, Microseconds (Major_Period));

   ETP.Register (T_A'Identity);
   ETP.Register (T_B'Identity);
   ETP.Register (T_C'Identity);
   ETP.Register (T_D'Identity);
   ETP.Register (Current_Task);

end Test;
