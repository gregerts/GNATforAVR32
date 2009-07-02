generic
   A, B : Integer;
package Quick_Random is

   subtype Distribution is Integer range A .. B;

   type Generator is limited private;

   function Random (Gen : not null access Generator) return Distribution;

   procedure Reset (Gen       : in out Generator;
                    Initiator : in     Integer);

   procedure Reset (Gen : in out Generator);

private

   type Generator is new Integer;

end Quick_Random;

