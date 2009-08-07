with GNAT.IO;
with Error;

package body Test is

   TA, TB, TC, TD : Timing_Event;

   ------------
   -- Worker --
   ------------

   protected body Worker is

      procedure Initialize
        (Event : in out Timing_Event;
         Epoch : Time)
      is
      begin

         Next := Epoch;

         Event.Set_Handler (Next, Handler'Access);

      end Initialize;

      procedure Handler (Event : in out Timing_Event) is
      begin

         Next := Next + Milliseconds (Period);

         Toggle_Pin (Port_B, Pin);

         Event.Set_Handler (Next, Handler'Access);

      end Handler;

   end Worker;

   --  Workers

   A : Worker (27,  125);
   B : Worker (28,  250);
   C : Worker (29,  500);
   D : Worker (30, 1000);

begin

   --  Configure GPIO pins for LEDs

   Configure_GPIO (Port_B, Range_To_Mask (27, 30));

   Clear_Pins (Port_B, Range_To_Mask (27, 30));

   --  Set up first execution of timers

   declare
      Epoch : Time := Clock + Milliseconds (100);
   begin
      A.Initialize (TA, Epoch);
      B.Initialize (TB, Epoch);
      C.Initialize (TC, Epoch);
      D.Initialize (TD, Epoch);
   end;

end Test;
