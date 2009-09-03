pragma Profile (Ravenscar);

with Ada.Real_Time, Demo;

procedure Main is
   pragma Priority (100);
begin
   delay until Ada.Real_Time.Time_Last;
end Main;
