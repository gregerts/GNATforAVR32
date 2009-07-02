package body Release_Mechanisms.Aperiodic is

   ---------------------------
   -- Wait_For_Next_Release --
   ---------------------------

   procedure Wait_For_Next_Release (S : in out Aperiodic_Release) is
   begin
      Suspend_Until_True (S.SO);
   end Wait_For_Next_Release;

   -------------
   -- Release --
   -------------

   procedure Release (S : in out Aperiodic_Release) is
   begin
      Set_True (S.SO);
   end Release;

end Release_Mechanisms.Aperiodic;
