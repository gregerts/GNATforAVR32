with Ada.Unchecked_Conversion;

package body Random_Time is

   function To_Time_Span is
      new Ada.Unchecked_Conversion (Long_Long_Integer, Time_Span);

   function To_Long_Long is
      new Ada.Unchecked_Conversion (Time_Span, Long_Long_Integer);

   --  From "Numerical Recepies in C++ 2. edition" page 282-283

   IM : constant := 2 ** 31 - 1;
   IA : constant := 7 ** 5;
   IQ : constant := 127773;
   IR : constant := 2836;

   ------------
   -- Random --
   ------------

   function Random (Gen : not null access Generator) return Time_Span is

      pragma Suppress (Range_Check);

      K : constant Integer := Gen.X / IQ;

      X : Integer;
      Y : Long_Long_Integer;

   begin

      X := IA * (Gen.X - K*IQ) - K*IR;

      if X < 0 then
         X := X + IM;
      end if;

      Gen.X := X;

      Y := (Gen.D * Long_Long_Integer (X)) / (IM + 1);

      return To_Time_Span (Y + Long_Long_Integer (Gen.A));

   end Random;

   ----------------
   -- Initialize --
   ----------------
   
   procedure Initialize (Gen  : in out Generator;
			 A, B : in     Time_Span)
   is
   begin
      Gen.A := To_Long_Long (A);
      Gen.D := To_Long_Long (B) - To_Long_Long (A) + 1;
   end Initialize;
   
   -----------
   -- Reset --
   -----------

   procedure Reset
     (Gen       : in out Generator;
      Initiator : in     Integer)
   is
   begin

      if Initiator = 0 then
         Gen.X := 123459876;
      else
         Gen.X := abs Initiator;
      end if;

   end Reset;

   -----------
   -- Reset --
   -----------

   procedure Reset (Gen : in out Generator) is
   begin
      Gen.X := 123459876;
   end Reset;

end Random_Time;
