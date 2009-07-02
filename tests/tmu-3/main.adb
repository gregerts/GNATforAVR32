pragma Profile (Ravenscar);

with Ada.Real_Time;
with Error;
with Test_Instance;

procedure Main is
begin
   delay until Ada.Real_Time.Time_Last;
end Main;
