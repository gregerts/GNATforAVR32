with Ada.Real_Time, Ada.Task_Identification, Ada.Interrupts;
use Ada.Real_Time, Ada.Task_Identification, Ada.Interrupts;

package Execution_Time_Poller is

   procedure Register (T : Task_Id);
   procedure Register (I : Interrupt_ID);

   procedure Run (P : Time_Span);
   pragma No_Return (Run);

end Execution_Time_Poller;
