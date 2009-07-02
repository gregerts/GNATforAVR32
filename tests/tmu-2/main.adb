pragma Profile (Ravenscar);

with GNAT.IO;

with Test.A;
with Test.B;
with Test.C;

with Error;

with Ada.Real_Time;

procedure Main is
   pragma Priority (250);
begin
   delay until Ada.Real_Time.Time_Last;
end Main;
