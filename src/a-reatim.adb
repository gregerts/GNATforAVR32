------------------------------------------------------------------------------
--                                                                          --
--                 GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                 --
--                                                                          --
--                         A D A . R E A L _ T I M E                        --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                     Copyright (C) 2001-2007, AdaCore                     --
--                                                                          --
-- GNARL is free software; you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. GNARL is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
--
--
--
--
--
--
--
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by Ada Core Technologies, Inc.     --
--                                                                          --
------------------------------------------------------------------------------

--  This is the Ravenscar version of this package for generic bare board
--  targets.

with System.Task_Primitives.Operations;
--  used for Monotonic_Clock

with Ada.Unchecked_Conversion;

package body Ada.Real_Time is

   package STPO renames System.Task_Primitives.Operations;

   -----------------------
   -- Local definitions --
   -----------------------

   type Integer_Duration is range
     -2 ** (Duration'Size - 1) .. 2 ** (Duration'Size - 1) - 1;
   for Integer_Duration'Size use Duration'Size;
   --  Type used to have an intermediate Integer representation of Duration.
   --  Sometimes, Duration and Time_Span are different types, so we must be
   --  careful when doing transformations between them in order not to lose
   --  precision gratuitously. Additionally, we do not want to use floating
   --  point operations here because this unit is used in run times where we
   --  avoid these operations. Therefore, transformations from Duration to
   --  Time_Span and vice versa are done at a low level, knowing that
   --  Duration is really represented as an Integer with units of Small.

   -----------------------
   -- Local subprograms --
   -----------------------

   function To_Duration is
     new Ada.Unchecked_Conversion (Integer_Duration, Duration);

   function To_Integer_Duration is
     new Ada.Unchecked_Conversion (Duration, Integer_Duration);

   ---------
   -- "*" --
   ---------

   function "*" (Left : Time_Span; Right : Integer) return Time_Span is
   begin
      return Left * Time_Span (Right);
   end "*";

   function "*" (Left : Integer; Right : Time_Span) return Time_Span is
   begin
      return Time_Span (Left) * Right;
   end "*";

   ---------
   -- "+" --
   ---------

   function "+" (Left : Time; Right : Time_Span) return Time is
   begin
      return Left + Time (Right);
   end "+";

   function "+" (Left : Time_Span; Right : Time) return Time is
   begin
      return Time (Left) + Right;
   end "+";

   function "+" (Left, Right : Time_Span) return Time_Span is
   begin
      return Time_Span (Long_Long_Integer (Left) + Long_Long_Integer (Right));
   end "+";

   ---------
   -- "-" --
   ---------

   function "-" (Left : Time; Right : Time_Span) return Time is
   begin
      return Left - Time (Right);
   end "-";

   function "-" (Left, Right : Time) return Time_Span is
   begin
      return Time_Span (Long_Long_Integer (Left) - Long_Long_Integer (Right));
   end "-";

   function "-" (Left, Right : Time_Span) return Time_Span is
   begin
      return Time_Span (Long_Long_Integer (Left) - Long_Long_Integer (Right));
   end "-";

   function "-" (Right : Time_Span) return Time_Span is
   begin
      return Time_Span (-Long_Long_Integer (Right));
   end "-";

   ---------
   -- "/" --
   ---------

   function "/" (Left, Right : Time_Span) return Integer is
   begin
      return Integer (Long_Long_Integer (Left) / Long_Long_Integer (Right));
   end "/";

   function "/" (Left : Time_Span; Right : Integer) return Time_Span is
   begin
      return Left / Time_Span (Right);
   end "/";

   -----------
   -- Clock --
   -----------

   function Clock return Time is
   begin
      return Time (STPO.Monotonic_Clock);
   end Clock;

   ------------------
   -- Microseconds --
   ------------------

   function Microseconds (US : Integer) return Time_Span is
   begin
      return Time_Span
        (Long_Long_Integer (US) * Long_Long_Integer (STPO.RT_Resolution)) /
        Time_Span (10#1#E6);
   end Microseconds;

   ------------------
   -- Milliseconds --
   ------------------

   function Milliseconds (MS : Integer) return Time_Span is
   begin
      return Time_Span
        (Long_Long_Integer (MS) * Long_Long_Integer (STPO.RT_Resolution)) /
        Time_Span (10#1#E3);
   end Milliseconds;

   -------------
   -- Minutes --
   -------------

   function Minutes (M : Integer) return Time_Span is
   begin
      return Milliseconds (M) * Integer'(60_000);
   end Minutes;

   -----------------
   -- Nanoseconds --
   -----------------

   function Nanoseconds (NS : Integer) return Time_Span is
   begin
      return Time_Span
        (Long_Long_Integer (NS) * Long_Long_Integer (STPO.RT_Resolution)) /
        Time_Span (10#1#E9);
   end Nanoseconds;

   -------------
   -- Seconds --
   -------------

   function Seconds (S : Integer) return Time_Span is
   begin
      return Milliseconds (S) * Integer'(1000);
   end Seconds;

   -----------
   -- Split --
   -----------

   procedure Split (T : Time; SC : out Seconds_Count; TS : out Time_Span) is
      Res : constant Time := Time (STPO.RT_Resolution);
   begin
      SC := Seconds_Count (T / Res);
      TS := Time_Span (T) - Time_Span (Time (SC) * Res);
   end Split;

   -------------
   -- Time_Of --
   -------------

   function Time_Of (SC : Seconds_Count; TS : Time_Span) return Time is
   begin
      return Time (SC) * Time (STPO.RT_Resolution) + TS;
   end Time_Of;

   -----------------
   -- To_Duration --
   -----------------

   function To_Duration (TS : Time_Span) return Duration is
      Min_Time_Span : constant :=
        Long_Long_Integer (Integer_Duration'First) *
        Long_Long_Integer (STPO.RT_Resolution) /
        Long_Long_Integer (1.0 / Duration'Small);
      --  Minimum value for a Time_Span variable that can be transformed into
      --  Duration without overflow.

      Max_Time_Span : constant :=
        Long_Long_Integer (Integer_Duration'Last) *
        Long_Long_Integer (STPO.RT_Resolution) /
        Long_Long_Integer (1.0 / Duration'Small);
      --  Maximum value for a Time_Span value that can be transformed into
      --  Duration without overflow.

   begin
      --  Perform range checks required by AI-00432. Use the intermediate
      --  Integer representation of Duration to allow for simple Integer
      --  operations.

      if TS <= Max_Time_Span and then TS >= Min_Time_Span then
         return To_Duration
           (Integer_Duration (Long_Long_Integer (TS) *
                              Long_Long_Integer (1.0 / Duration'Small) /
                              Long_Long_Integer (STPO.RT_Resolution)));

      else
         --  The resulting conversion would be out of range for Duration

         raise Constraint_Error;
      end if;
   end To_Duration;

   ------------------
   -- To_Time_Span --
   ------------------

   function To_Time_Span (D : Duration) return Time_Span is
      Min_Duration : constant :=
        Long_Long_Integer (Time_Span'First) *
        Long_Long_Integer (1.0 / Duration'Small) /
        Long_Long_Integer (STPO.RT_Resolution);
      --  Minimum value for an Duration value that can be transformed into
      --  Time_Span without overflow.

      Max_Duration : constant :=
        Long_Long_Integer (Time_Span'Last) *
        Long_Long_Integer (1.0 / Duration'Small) /
        Long_Long_Integer (STPO.RT_Resolution);
      --  Maximum value for a Duration value that can be transformed into
      --  Time_Span without overflow.

      Value : constant Long_Long_Integer :=
        Long_Long_Integer (To_Integer_Duration (D));
      --  Intermediate representation of the value to transform

   begin
      --  Perform range checks required by AI-00432. Use the intermediate
      --  Integer representation of Duration to allow for simple Integer
      --  operations.

      if Value <= Max_Duration and then Value >= Min_Duration then
         return Time_Span
           (Value *
            Long_Long_Integer (STPO.RT_Resolution) /
            Long_Long_Integer (1.0 / Duration'Small));

      else
         --  The resulting conversion would be out of range for Time_Span

         raise Constraint_Error;
      end if;
   end To_Time_Span;

end Ada.Real_Time;
