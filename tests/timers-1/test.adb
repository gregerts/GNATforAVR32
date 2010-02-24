with GNAT.IO;
with Error;

package body Test is

   TE : Timing_Event;

   ------------
   -- Worker --
   ------------

   protected body Worker is

      procedure Initialize (Epoch : Time) is
      begin
         Next := Epoch;

         Clear_Pin (Port_B, 27);
         Set_Pins (Port_B, Range_To_Mask (28, 30));

         Set_Handler (TE, Next, Handler'Access);

      end Initialize;

      procedure Handler (Event : in out Timing_Event) is
         A, B : Natural;
      begin

         if Up then
            A   := LED + 27;
            LED := LED + 1;
            B   := LED + 27;
            Up  := LED < 3;
         else
            B   := LED + 27;
            LED := LED - 1;
            A   := LED + 27;
            Up  := LED = 0;
         end if;

         Toggle_Pins (Port_B, Range_To_Mask (A, B));

         Next := Next + Microseconds (66_667);

         Set_Handler (TE, Next, Handler'Access);

      end Handler;

   end Worker;

begin

   --  Configure GPIO pins for LEDs

   Configure_GPIO (Port_B, Range_To_Mask (27, 30), Output => True);

   --  Configure interrupt line as peripheral

   Worker.Initialize (Clock);

end Test;
