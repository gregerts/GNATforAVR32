with Ada.Exceptions;
with GNAT.IO;
with System.Machine_Code;

use GNAT.IO;
use Ada.Exceptions;

package body Test is

   ---------------
   -- Busy_Wait --
   ---------------

   procedure Busy_Wait (C : Natural) is

      use System.Machine_Code;

      I : Integer := C - 1;

   begin
      Asm ("1:"         & ASCII.LF & ASCII.HT &
           "nop"        & ASCII.LF & ASCII.HT &
           "nop"        & ASCII.LF & ASCII.HT &
           "sub  %0, 1" & ASCII.LF & ASCII.HT &
           "nop"        & ASCII.LF & ASCII.HT &
           "nop"        & ASCII.LF & ASCII.HT &
           "nop"        & ASCII.LF & ASCII.HT &
           "cp.w %0, 0" & ASCII.LF & ASCII.HT &
           "nop"        & ASCII.LF & ASCII.HT &
           "nop"        & ASCII.LF & ASCII.HT &
           "brge 1b",
           Inputs => Integer'Asm_Input ("r", I),
           Clobber => "cc",
           Volatile => True);
   end Busy_Wait;

end Test;
