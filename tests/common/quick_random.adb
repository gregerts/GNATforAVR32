package body Quick_Random is

   type Intermediate is mod 2 ** 64;
   for Intermediate'Size use 64;

   --  From "Numerical Recepies in C++ 2. edition" page 282-283

   IM : constant := 2 ** 31 - 1;
   IA : constant := 7 ** 5;
   IQ : constant := 127773;
   IR : constant := 2836;

   ------------
   -- Random --
   ------------

   function Random (Gen : not null access Generator) return Distribution is

      pragma Suppress (Range_Check);

      K : constant Generator := Generator (Gen.all / IQ);

      X : Generator;
      Y : Intermediate;

   begin

      X := IA * (Gen.all - K*IQ) - K*IR;

      if X < 0 then
         X := X + IM;
      end if;

      Gen.all := X;

      Y := (Intermediate (B - A + 1) * Intermediate (X)) / (IM + 1);

      return A + Distribution'Base (Y);

   end Random;

   -----------
   -- Reset --
   -----------

   procedure Reset
     (Gen       : in out Generator;
      Initiator : in     Integer)
   is
   begin

      if Initiator = 0 then
         Gen := 123459876;
      else
         Gen := Generator (abs Initiator);
      end if;

   end Reset;

   -----------
   -- Reset --
   -----------

   procedure Reset (Gen : in out Generator) is
   begin
      Gen := 123459876;
   end Reset;

end Quick_Random;
