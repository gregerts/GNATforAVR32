------------------------------------------------------------------
--  Adapted from "Concurrent and Real-Time Programming in Ada"  --
--               by Alan Burns and Andy Wellings.               --
------------------------------------------------------------------

with Ada.Execution_Time.Timers, Ada.Task_Identification;
use Ada.Execution_Time.Timers, Ada.Task_Identification;

package body Real_Time_Tasks is

   task body Real_Time_Task is
      pragma Suppress (Access_Check);
   begin
      S.Tid := Current_Task;
      S.Initialize;
      loop
         R.Wait_For_Next_Release;
         S.Code;
      end loop;
   end Real_Time_Task;

end Real_Time_Tasks;
