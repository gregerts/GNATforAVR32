package body Interrupt_Handlers is

   -----------------------
   -- Interrupt_Handler --
   -----------------------

   protected body Interrupt_Handler is

      -------------
      -- Handler --
      -------------

      procedure Handler is
         pragma Suppress (Access_Check);
      begin
         S.Handler;
      end Handler;

   end Interrupt_Handler;

end Interrupt_Handlers;
