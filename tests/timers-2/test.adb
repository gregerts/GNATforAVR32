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
	 Now : Time := Clock;
      begin
	 pragma Assert (Now > Next);
	 pragma Assert ((Now - Next) < Microseconds (50));
	 
         Next := Next + Milliseconds (Period);
         Toggle_Pin (Port, Pin);
         Event.Set_Handler (Next, Handler'Access);
	 
      end Handler;

   end Worker;

   --  Workers

   A : Worker (Port_B, 27, 100);
   B : Worker (Port_B, 28, 5);
   C : Worker (Port_B, 29, 3);
   D : Worker (Port_B, 30, 2);

begin

   --  Configure GPIO pins for LEDs

   Configure_GPIO (Port_B, Range_To_Mask (27, 30), Output => True);

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
