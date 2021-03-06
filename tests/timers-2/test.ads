with System;
with Ada.Real_Time.Timing_Events;
with GPIO_Controller;

use Ada.Real_Time;
use Ada.Real_Time.Timing_Events;
use GPIO_Controller;

package Test is

   ------------
   -- Worker --
   ------------

   protected type Worker (Port   : Port_Id;
                          Pin    : Natural;
                          Period : Natural) is

      pragma Priority (System.Interrupt_Priority'Last);

      procedure Initialize
        (Event : in out Timing_Event;
         Epoch : Time);

      procedure Handler (Event : in out Timing_Event);

   private
      Next : Time;
   end Worker;

end Test;
