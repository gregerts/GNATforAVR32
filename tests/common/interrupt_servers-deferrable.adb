package body Interrupt_Servers.Deferrable is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (S : in out Deferrable_Interrupt_Server) is
   begin
      S.M.Initialize;
   end Initialize;

   ---------------
   -- Mechanism --
   ---------------

   protected body Mechanism is

      ----------------
      -- Initialize --
      ----------------

      procedure Initialize is
      begin
         Execution_Timer := new Interrupt_Timer (Param.State.Identity);
         Next := Epoch;
         Replenish_Event.Set_Handler (Next, Replenish'Access);
      end Initialize;

      ---------------
      -- Replenish --
      ---------------

      procedure Replenish (Event : in out Timing_Event) is
      begin
         Execution_Timer.Set_Handler (Param.Budget, Overrun'Access);
         if Disabled then
            Disabled := False;
            Param.State.Enable;
         end if;
         Next := Next + Param.Period;
         Event.Set_Handler (Next, Replenish'Access);
      end Replenish;

      -------------
      -- Overrun --
      -------------

      procedure Overrun (TM : in out Timer) is
      begin
         if not Disabled then
            Disabled := True;
            Param.State.Disable;
         end if;
      end Overrun;

   end Mechanism;

end Interrupt_Servers.Deferrable;
