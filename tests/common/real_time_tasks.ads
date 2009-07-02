------------------------------------------------------------------
--  Adapted from "Concurrent and Real-Time Programming in Ada"  --
--               by Alan Burns and Andy Wellings.               --
------------------------------------------------------------------

with System, Ada.Real_Time, Release_Mechanisms, Task_States;
use System, Ada.Real_Time, Release_Mechanisms, Task_States;

package Real_Time_Tasks is

   Size : constant := 2048;

   task type Real_Time_Task
     (P : Priority;
      S : not null Any_Task_State;
      R : not null Any_Release_Mechanism) is

      pragma Priority (P);
      pragma Storage_Size (Size);

   end Real_Time_Task;

end Real_Time_Tasks;
