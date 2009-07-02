with System;
with Ada.Real_Time.Timing_Events;
with GPIO_Controller;

use Ada.Real_Time;
use Ada.Real_Time.Timing_Events;
use GPIO_Controller;

package Raventest is

   ------------
   -- Worker --
   ------------

   protected Worker is

      pragma Priority (System.Interrupt_Priority'Last);

      procedure Initialize (Epoch : Time);
      procedure Handler (Event : in out Timing_Event);

   private
      Next : Time;
      LED  : Natural := 0;
      Up   : Boolean := True;
   end Worker;

end Raventest;
