with Ada.Real_Time;
with Test;

procedure Main is
   pragma Priority (150);
   use Ada.Real_Time;
begin
   delay until Time_Last;
end Main;
