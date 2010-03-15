with System, Ada.Real_Time.Timing_Events, Quick_Random;
use System, Ada.Real_Time, Ada.Real_Time.Timing_Events;

generic
   A, B, N : Natural;
package Test is

   ---------
   -- Run --
   ---------

   procedure Run;
   pragma No_Return (Run);

end Test;
