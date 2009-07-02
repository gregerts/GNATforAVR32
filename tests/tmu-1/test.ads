with System;

package Test is

   --------------
   -- Periodic --
   --------------

   task type Periodic
     (P : System.Priority;
      T : Natural;
      C : Natural)
   is
      pragma Priority (P);
      pragma Storage_Size (2048);
   end Periodic;

   ----------------
   -- Test suite --
   ----------------

   T_A : Periodic (90,  50_000,  5_000);
   T_B : Periodic (80, 100_000, 10_000);
   T_C : Periodic (70, 200_000, 20_000);
   T_D : Periodic (60, 400_000, 40_000);

   Major_Period    : constant := 400_000;
   Number_Of_Tasks : constant := 5;

   ---------
   -- Run --
   ---------

   procedure Run;

end Test;
