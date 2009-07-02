package body Release_Mechanisms.Controlled_Periodic is

   ---------------------------
   -- Wait_For_Next_Release --
   ---------------------------

   procedure Wait_For_Next_Release (R : in out Controlled_Periodic_Release) is
   begin
      if R.First then
         R.First := False;
         R.M.Initialize;
      end if;
      R.M.Wait;
   end Wait_For_Next_Release;

   ---------------
   -- Mechanism --
   ---------------

   protected body Mechanism is

      ----------------
      -- Initialize --
      ----------------

      procedure Initialize is
      begin
         Execution_Timer := new Timer (S.Tid'Access);
         Next := Epoch;
         Event_Period.Set_Handler (Next, Release'Access);
      end Initialize;

      -------------
      -- Release --
      -------------

      procedure Release (TE : in out Timing_Event) is
      begin
         if Wait'Count = 0 then
            S.Deadline_Miss;
         end if;
         Execution_Timer.Set_Handler (S.Budget, Overran'Access);
         Next := Next + S.Period;
         TE.Set_Handler (Next, Release'Access);
         Open := True;
      end Release;

      -------------
      -- Overran --
      -------------

      procedure Overran (TM : in out Timer) is
      begin
         TM.Set_Handler (S.Recovery, Overran'Access);
         S.Overrun;
      end Overran;

      ----------
      -- Wait --
      ----------

      entry Wait when Open is
      begin
         Open := False;
      end Wait;

   end Mechanism;

end Release_Mechanisms.Controlled_Periodic;
