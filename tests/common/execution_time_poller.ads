with Ada.Real_Time, Ada.Task_Identification;
use Ada.Real_Time, Ada.Task_Identification;

package Execution_Time_Poller is

   procedure Initialize
     (N : Positive;
      P : Time_Span);

   procedure Register (Tid : Task_Id);

   procedure Run;
   pragma No_Return (Run);

end Execution_Time_Poller;
