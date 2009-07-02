with Ada.Unchecked_Conversion;
with GNAT.IO;
with System.Machine_Code;

use GNAT.IO;
use System.Machine_Code;

package body Utilities is

   type Byte is mod 2 ** 8;
   for Byte'Size use 8;

   type Byte_Array is array (Natural range <>) of Byte;
   pragma Pack (Byte_Array);
   pragma Suppress_Initialization (Byte_Array);

   To_Character : constant array (0 .. 15) of Character := "0123456789ABCDEF";

   ---------------
   -- Busy_Wait --
   ---------------

   procedure Busy_Wait (C : Natural) is
      I : Integer := 5 * C - 1;
   begin

      --  This procedure is valid only for CPU frequencies that are
      --  multiples of 12 MHz (1 us = 12 cycles).

      Asm ("1:"         & ASCII.LF & ASCII.HT &
             "nop"        & ASCII.LF & ASCII.HT &
             "sub  %0, 1" & ASCII.LF & ASCII.HT &
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

   -------------
   -- Put_Hex --
   -------------

   procedure Put_Hex (Item : Item_Type) is

      subtype Item_Array is Byte_Array (0 .. (Item_Type'Size / 8) - 1);

      function To_Item_Array is new
        Ada.Unchecked_Conversion (Item_Type, Item_Array);

      Bytes : constant Item_Array := To_Item_Array (Item);

      B : Natural;
      S : Boolean := Leading_Zeroes;

   begin

      for I in Bytes'Range loop
         --  Put high half-byte

         B := Natural (Bytes (I)) / 16;

         if S or B > 0 then

            S := True;

            Put (To_Character (B));

         end if;

         --  Put low half-byte

         B := Natural (Bytes (I)) mod 16;

         if S or B > 0 then

            S := True;

            Put (To_Character (B));

         end if;

      end loop;

      if not S then
         Put ('0');
      end if;

   end Put_Hex;

end Utilities;
