pragma Profile (Ravenscar);

with Test;
with Error;

procedure Main is
   pragma Priority (50);
begin
   Test.Run;
end Main;
