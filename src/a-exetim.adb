------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                   A D A . E X E C U T I O N _ T I M E                    --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                Copyright (C) 2008, Kristoffer N. Gregertsen              --
--                                                                          --
-- This specification is derived from the Ada Reference Manual for use with --
-- GNAT. The copyright notice above, and the license provisions that follow --
-- apply solely to the  contents of the part following the private keyword. --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
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
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Unchecked_Conversion;
with System.Tasking;
with System.Task_Primitives.Operations;
with System.OS_Interface;

package body Ada.Execution_Time is

   package STPO renames System.Task_Primitives.Operations;
   package OSI  renames System.OS_Interface;
   package TMU  renames System.BB.TMU;

   use type OSI.Time;
   use type OSI.Time_Span;

   --------------------------
   -- Conversion constants --
   --------------------------

   CPU_Ticks : constant := TMU.CPU_Ticks_Per_Second / OSI.Ticks_Per_Second;

   --------------------------
   -- Conversion functions --
   --------------------------

   function To_Task_Id is
      new Ada.Unchecked_Conversion (Ada.Task_Identification.Task_Id,
                                    System.Tasking.Task_Id);

   function To_Time is
      new Ada.Unchecked_Conversion (Ada.Real_Time.Time,
                                    OSI.Time);

   function To_Time_Span is
      new Ada.Unchecked_Conversion (Ada.Real_Time.Time_Span,
                                    OSI.Time_Span);

   function To_Time is
      new Ada.Unchecked_Conversion (CPU_Time,
                                    Ada.Real_Time.Time);

   function To_Time_Span is
      new Ada.Unchecked_Conversion (CPU_Time,
                                    Ada.Real_Time.Time_Span);

   -----------
   -- Clock --
   -----------

   function Clock
     (T : Ada.Task_Identification.Task_Id
          := Ada.Task_Identification.Current_Task)
      return CPU_Time
   is
   begin
      return CPU_Time (TMU.Time_Of (STPO.Task_Clock (To_Task_Id (T))));
   end Clock;

   ---------
   -- "+" --
   ---------

   function "+"
     (Left  : CPU_Time;
      Right : Ada.Real_Time.Time_Span)
      return CPU_Time
   is
   begin
      return Left + CPU_Time (To_Time_Span (Right) * CPU_Ticks);
   end "+";

   ---------
   -- "+" --
   ---------

   function "+"
     (Left  : Ada.Real_Time.Time_Span;
      Right : CPU_Time)
      return CPU_Time
   is
   begin
      return Right + Left;
   end "+";

   ---------
   -- "-" --
   ---------

   function "-"
     (Left  : CPU_Time;
      Right : Ada.Real_Time.Time_Span)
      return CPU_Time
   is
   begin
      return Left - CPU_Time (To_Time_Span (Right) * CPU_Ticks);
   end "-";

   ---------
   -- "-" --
   ---------

   function "-"
     (Left  : CPU_Time;
      Right : CPU_Time)
      return Ada.Real_Time.Time_Span
   is
   begin
      return To_Time_Span ((Left - Right) / CPU_Ticks);
   end "-";

   -----------
   -- Split --
   -----------

   procedure Split
     (T  : CPU_Time;
      SC : out Ada.Real_Time.Seconds_Count;
      TS : out Ada.Real_Time.Time_Span)
   is
   begin
      Ada.Real_Time.Split (To_Time (T / CPU_Ticks), SC, TS);
   end Split;

   -------------
   -- Time_Of --
   -------------

   function Time_Of
     (SC : Ada.Real_Time.Seconds_Count;
      TS : Ada.Real_Time.Time_Span := Ada.Real_Time.Time_Span_Zero)
      return CPU_Time
   is
   begin
      return CPU_Time (To_Time (Ada.Real_Time.Time_Of (SC, TS)) * CPU_Ticks);
   end Time_Of;

end Ada.Execution_Time;
