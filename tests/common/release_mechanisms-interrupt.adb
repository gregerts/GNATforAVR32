package body Release_Mechanisms.Interrupt is

   ---------------------------
   -- Wait_For_Next_Release --
   ---------------------------

   procedure Wait_For_Next_Release (R : in out Interrupt_Release) is
   begin
      R.M.Wait;
   end Wait_For_Next_Release;

   ---------------
   -- Mechanism --
   ---------------

   protected body Mechanism is

      ----------
      -- Wait --
      ----------

      entry Wait when Open is
      begin
         Open := False;
      end Wait;

      -------------
      -- Handler --
      -------------

      procedure Handler is
      begin
         S.Handler;
         Open := Open or S.Release;
      end Handler;

   end Mechanism;

end Release_Mechanisms.Interrupt;
