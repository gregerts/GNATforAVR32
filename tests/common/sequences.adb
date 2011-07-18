package body Sequences is

   ---------------
   -- Sequencer --
   ---------------

   protected body Sequencer is

      ----------------
      -- Initialize --
      ----------------

      procedure Reset is
      begin
         Prev := 0;
         Open := False;
      end Reset;

      -------------
      -- Handler --
      -------------

      procedure Handler (Event : in out Any_Event) is
         E : access Sequencial_Event :=
           Sequence_Event (Any_Event'Class (Event))'Access;
      begin

         pragma Assert (E.S > Prev);
         pragma Assert (not Open);

         Prev := E.S;
         Open := E.Final;

      end Handler;

      ----------
      -- Wait --
      ----------

      entry Wait when Open is
      begin
         null;
      end Wait;

   end Sequencer;

end Sequences;
