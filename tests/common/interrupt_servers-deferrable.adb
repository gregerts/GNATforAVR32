package body Interrupt_Servers.Deferrable is

   --------------
   -- Register --
   --------------

   procedure Register
     (S : in out Deferrable_Interrupt_Server;
      I : Any_Interrupt_State)
   is
   begin
      S.M.Register (I);
   end Register;

   ---------------
   -- Mechanism --
   ---------------

   protected body Mechanism is

      --------------
      -- Register --
      --------------

      procedure Register (I : Any_Interrupt_State) is
      begin
         pragma Assert (Registered < State_Array'Last);
         if Registered = 0 then
            Execution_Timer := new Interrupt_Timer (Param.Pri);
            Next := Epoch;
            Replenish_Event.Set_Handler (Next, Replenish'Access);
         end if;
         Registered := Registered + 1;
         States (Registered) := I;
      end Register;

      ---------------
      -- Replenish --
      ---------------

      procedure Replenish (Event : in out Timing_Event) is
      begin
         Execution_Timer.Set_Handler (Param.Budget, Overrun'Access);
         if Disabled then
            Disabled := False;
            for I in 1 .. Registered loop
               States (I).Enable;
            end loop;
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
            for I in 1 .. Registered loop
               States (I).Disable;
            end loop;
         end if;
      end Overrun;

   end Mechanism;

end Interrupt_Servers.Deferrable;
