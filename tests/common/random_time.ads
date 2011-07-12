with Ada.Real_Time;
use Ada.Real_Time;

package Random_Time is

   type Generator is limited private;

   function Random (Gen : not null access Generator) return Time_Span;

   procedure Initialize (Gen  : in out Generator;
			 A, B : in     Time_Span);
   
   procedure Reset (Gen       : in out Generator;
                    Initiator : in     Integer);

   procedure Reset (Gen : in out Generator);

private

   type Generator is
      record
	 X    : Integer;
	 A, D : Long_Long_Integer;
      end record;

end Random_Time;

