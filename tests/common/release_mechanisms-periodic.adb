package body Release_Mechanisms.Periodic is

   procedure Wait_For_Next_Release (R : in out Periodic_Release) is
   begin

      if Clock > R.Next then
         R.S.Deadline_Miss;
      end if;

      delay until R.Next;

      R.Next := R.Next + R.S.Period;

   end Wait_For_Next_Release;

end Release_Mechanisms.Periodic;
