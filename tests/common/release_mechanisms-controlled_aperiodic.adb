with Epoch_Support;
use Epoch_Support;

package body Release_Mechanisms.Controlled_Aperiodic is

   ---------------------------
   -- Wait_For_Next_Release --
   ---------------------------

   procedure Wait_For_Next_Release
     (R : in out Controlled_Aperiodic_Release)
   is
   begin
      if R.First then
         R.First := False;
         R.M.Initialize;
      end if;
      R.M.Wait;
   end Wait_For_Next_Release;

   -------------
   -- Release --
   -------------

   procedure Release (R : in out Controlled_Aperiodic_Release) is
   begin
      R.M.Release;
   end Release;

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
         Event_Replenish.Set_Handler (Next, Replenish'Access);
      end Initialize;

      -------------
      -- Release --
      -------------

      procedure Release is
      begin
         Released := True;
         Open := not Suspended;
      end Release;

      ----------
      -- Wait --
      ----------

      entry Wait when Open is
      begin
         pragma Assert (not Suspended);
         Released := False;
         Open := False;
      end Wait;

      ---------------
      -- Replenish --
      ---------------

      procedure Replenish (TE : in out Timing_Event) is
      begin

         Execution_Timer.Set_Handler (S.Budget, Overran'Access);

         if Suspended then
            Suspended := False;
            Open := Released;
            S.Continue;
         end if;

         Next := Next + S.Replenish_Period;
         TE.Set_Handler (Next, Replenish'Access);

      end Replenish;

      -------------
      -- Overran --
      -------------

      procedure Overran (TM : in out Timer) is
      begin
         if not Suspended then
            Suspended := True;
            Open := False;
            S.Hold;
            TM.Set_Handler (S.Recovery, Overran'Access);
         else
            S.Overrun;
         end if;
      end Overran;

   end Mechanism;

end Release_Mechanisms.Controlled_Aperiodic;
