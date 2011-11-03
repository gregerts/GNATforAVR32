with System;

generic
   type Any_Event is tagged limited private;
package Sequences is

   type Sequence_Event is new Any_Event with
      record
         S : Positive;
         Final : Boolean;
      end record;

   protected Sequencer is

      procedure Reset;
      
      procedure Handler (Event : in out Any_Event);

      entry Wait_For_Final;

      pragma Priority (System.Any_Priority'Last);
      
   private

      Prev : Natural;
      Open : Boolean := False;

   end Sequencer;

   Sequence_Error : exception;
   
end Sequences;
