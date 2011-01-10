with Ada.Task_Identification;
with Ada.Execution_Time.Timers;

package Ada.Execution_Time.Interrupts.Timers is

   type Timer (I : Ada.Interrupts.Interrupt_ID)
      is new Ada.Execution_Time.Timers.Timer
     (Ada.Task_Identification.Null_Task_Id'Access)
     with private;

   Timer_Resource_Error : exception;

private

   type Timer (I : Ada.Interrupts.Interrupt_ID)
      is new Ada.Execution_Time.Timers.Timer
     (Ada.Task_Identification.Null_Task_Id'Access)
     with null record;

end Ada.Execution_Time.Interrupts.Timers;
