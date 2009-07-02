with GNAT.IO;
with Ada.Real_Time;
with GPIO_Controller;
with External_Interrupts;
with Ada.Task_Identification;

use Ada.Real_Time;
use GPIO_Controller;
use External_Interrupts;
use Ada.Task_Identification;

package body Test.C is

   use type Ada.Interrupts.Interrupt_ID;

   Pin       : constant := 4;
   Interrupt : constant := External_Interrupts.EIM_5;

   TM : Timer (Interrupt_Server (EIM_5_Priority)'Access);

   -----------
   -- Event --
   -----------

   protected body Event is

      ------------
      -- Signal --
      ------------

      procedure Signal is
      begin
         Clear (Interrupt);
         Busy_Wait (100);
      end Signal;

   end Event;

   -------------
   -- Manager --
   -------------

   protected body Manager is

      ----------------
      -- Initialize --
      ----------------

      procedure Initialize is
      begin

         Next := Next + Milliseconds (1);

         TM.Set_Handler (Next, Handler'Access);

      end Initialize;

      -------------
      -- Handler --
      -------------

      procedure Handler (TM : in out Timer) is
         Now : constant CPU_Time := Interrupt_Clock (EIM_5_Priority);
      begin
         pragma Assert (TM.Current_Handler = null);

         GNAT.IO.Put ('I');

         Next := Next + Milliseconds (1);

         TM.Set_Handler (Next, Handler'Access);
      end Handler;

   end Manager;

begin

   GNAT.IO.New_Line;

   --  Initialize Manager

   Manager.Initialize;

   --  Configure GPIO pin for peripheral B

   Configure_Peripheral (Port_A, Pin, Peripheral_B);

   --  Enable external interrupt on falling edge

   Trigger_Edge (Interrupt, Falling, True);

   Enable (Interrupt);

end Test.C;
