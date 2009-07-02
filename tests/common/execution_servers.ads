with Ada.Real_Time, Task_States.Aperiodic;
use Ada.Real_Time, Task_States.Aperiodic;

package Execution_Servers is

   type Server_Parameters is
      record
         Period : Time_Span;
         Budget : Time_Span;
      end record;

   type Execution_Server is limited interface;

   procedure Schedule
     (ES : in out Execution_Server;
      S  : Any_Aperiodic_Task_State);

   type Any_Execution_Server is access all Execution_Server'Class;

end Execution_Servers;
