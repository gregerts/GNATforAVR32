------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                              G N A T . I O                               --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                     Copyright (C) 1995-2006, AdaCore                     --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
-- to  the  Free Software Foundation,  51  Franklin  Street,  Fifth  Floor, --
-- Boston, MA 02110-1301, USA.                                              --
--                                                                          --
--
--
--
--
--
--
--
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

with System.BB.Serial_Output;

package body GNAT.IO is

   --------------
   -- New_Line --
   --------------

   procedure New_Line renames System.BB.Serial_Output.New_Line;

   ---------
   -- Put --
   ---------

   procedure Put (C : Character) is
   begin
      System.BB.Serial_Output.Put (C);
   end Put;

   ---------
   -- Put --
   ---------

   procedure Put (X : Integer) is
      Int   : Integer;
      S     : String (1 .. Integer'Width);
      First : Natural := S'Last + 1;
      Val   : Natural;

   begin
      if X < 0 then
         Int := -X;
      else
         Int := X;
      end if;

      loop
         Val := Int mod 10;
         Int := (Int - Val) / 10;
         First := First - 1;
         S (First) := Character'Val (Val + Character'Pos ('0'));
         exit when Int = 0;
      end loop;

      if X < 0 then
         First := First - 1;
         S (First) := '-';
      end if;

      Put (S (First .. S'Last));
   end Put;

   ---------
   -- Put --
   ---------

   procedure Put (S : String) is
   begin
      System.BB.Serial_Output.Put (S);
   end Put;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (S : String) is
   begin
      System.BB.Serial_Output.Put_Line (S);
   end Put_Line;

end GNAT.IO;
