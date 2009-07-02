with Epoch_Support;
use Epoch_Support;

package body Release_Mechanisms.Controlled_Sporadic is

   ---------------------------
   -- Wait_For_Next_Release --
   ---------------------------

   procedure Wait_For_Next_Release (R : in out Controlled_Sporadic_Release) is
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

   procedure Release (R : in out Controlled_Sporadic_Release) is
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
         Event_MIT.Set_Handler (Epoch, Release_Allowed'Access);
      end Initialize;

      ----------
      -- Wait --
      ----------

      entry Wait when Open is
      begin
         Execution_Timer.Set_Handler (S.Budget, Overran'Access);
         Event_MIT.Set_Handler (S.MIT, Release_Allowed'Access);
         Released := False;
         Allowed := False;
         Open := False;
      end Wait;

      -------------
      -- Release --
      -------------

      procedure Release is
      begin
         Released := True;
         Open := Allowed;
      end Release;

      ---------------------
      -- Release_Allowed --
      ---------------------

      procedure Release_Allowed (TE : in out Timing_Event) is
      begin
         if Wait'Count = 0 then
            S.Deadline_Miss;
         end if;
         Allowed := True;
         Open := Released;
      end Release_Allowed;

      -------------
      -- Overran --
      -------------

      procedure Overran (TM : in out Timer) is
      begin
         TM.Set_Handler (S.Recovery, Overran'Access);
         S.Overrun;
      end Overran;

   end Mechanism;

end Release_Mechanisms.Controlled_Sporadic;
