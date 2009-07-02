with Epoch_Support;
use Epoch_Support;

package body Release_Mechanisms.Sporadic is

   ---------------------------
   -- Wait_For_Next_Release --
   ---------------------------

   procedure Wait_For_Next_Release (R : in out Sporadic_Release) is
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

   procedure Release (R : in out Sporadic_Release) is
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
         Event_MIT.Set_Handler (Epoch, Release_Allowed'Access);
      end Initialize;

      ----------
      -- Wait --
      ----------

      entry Wait when Open is
      begin
         Open     := False;
         Allowed  := False;
         Released := False;
         Event_MIT.Set_Handler (S.MIT, Release_Allowed'Access);
      end Wait;

      -------------
      -- Release --
      -------------

      procedure Release is
      begin
         Released := True;
         Open     := Allowed;
      end Release;

      ---------------------
      -- Release_Allowed --
      ---------------------

      procedure Release_Allowed (TE : in out Timing_Event) is
      begin
         Allowed := True;
         Open    := Released;
      end Release_Allowed;

   end Mechanism;

end Release_Mechanisms.Sporadic;
