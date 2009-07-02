pragma Profile (Ravenscar);

with Test;

procedure Main is
   pragma Priority (100);
begin
   Test.Run;
end Main;
