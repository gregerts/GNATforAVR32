with Ada.Execution_Time.Timers;
with Ada.Interrupts.Names;

use Ada.Execution_Time;
use Ada.Execution_Time.Timers;
use Ada.Interrupts.Names;

package Test.C is

   --  This package tests interrupt timers

   protected Event is
      procedure Signal;

      pragma Attach_Handler (Signal, EIM_5);
      pragma Priority (EIM_5_Priority);
   end Event;

   protected Manager is
      procedure Initialize;
      procedure Handler (TM : in out Timer);

      pragma Priority (Min_Handler_Ceiling);
   private
      Next : CPU_Time := CPU_Time_First;
   end Manager;

end Test.C;
