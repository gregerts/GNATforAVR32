with Quick_Random;
with Ada.Text_IO;
with Ada.Integer_Text_IO;
with Ada.Unchecked_Conversion;

procedure Random_Test is

   package QR is new Quick_Random (0, 30_000);
   use QR;

   function To_Integer is new Ada.Unchecked_Conversion (Generator, Integer);

   Gen : aliased Generator;
   X : Integer;

begin

   Reset (Gen, 1);

   for I in 0 .. 256 * 100_000 loop
      X := Random (Gen'Access);
      if I mod 100_000 = 0 then
         Ada.Integer_Text_IO.Put (To_Integer (Gen), 0);
         Ada.Text_IO.New_Line;
      end if;
   end loop;

end Random_Test;




