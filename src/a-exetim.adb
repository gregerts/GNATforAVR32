------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                   A D A . E X E C U T I O N _ T I M E                    --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--             Copyright (C) 2008-2011, Kristoffer N. Gregertsen            --
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

with Ada.Execution_Time.Interrupts;
with Ada.Interrupts;
with Ada.Unchecked_Conversion;
with System.Tasking;
with System.Task_Primitives.Operations;

package body Ada.Execution_Time is

   package STPO renames System.Task_Primitives.Operations;
   package SBT  renames System.BB.Time;

   use type Ada.Real_Time.Time;
   use type Ada.Real_Time.Time_Span;

   --------------------------
   -- Conversion functions --
   --------------------------

   function To_Task_Id is
      new Ada.Unchecked_Conversion (Ada.Task_Identification.Task_Id,
                                    System.Tasking.Task_Id);

   function To_CPU_Time is
      new Ada.Unchecked_Conversion (Ada.Real_Time.Time, CPU_Time);

   function To_CPU_Time is
      new Ada.Unchecked_Conversion (Ada.Real_Time.Time_Span, CPU_Time);

   function To_Time is
      new Ada.Unchecked_Conversion (CPU_Time, Ada.Real_Time.Time);

   function To_Time_Span is
      new Ada.Unchecked_Conversion (CPU_Time, Ada.Real_Time.Time_Span);

   -----------
   -- Clock --
   -----------

   function Clock
     (T : Ada.Task_Identification.Task_Id
          := Ada.Task_Identification.Current_Task)
      return CPU_Time
   is
   begin
      return CPU_Time (SBT.Elapsed_Time (STPO.Task_Clock (To_Task_Id (T))));
   end Clock;

   --------------------------
   -- Clock_For_Interrupts --
   --------------------------

   function Clock_For_Interrupts return CPU_Time is
      Sum : CPU_Time := 0;
   begin

      for I in Ada.Interrupts.Interrupt_ID loop
         Sum := Sum + Interrupts.Clock (I);
      end loop;

      return Sum;

   end Clock_For_Interrupts;

   ---------
   -- "+" --
   ---------

   function "+"
     (Left  : CPU_Time;
      Right : Ada.Real_Time.Time_Span)
      return CPU_Time
   is
   begin
      return Left + To_CPU_Time (Right);
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
      return Right + To_CPU_Time (Left);
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
      return Left - To_CPU_Time (Right);
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
      return To_Time_Span (Left - Right);
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
      Ada.Real_Time.Split (To_Time (T), SC, TS);
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
      return To_CPU_Time (Ada.Real_Time.Time_Of (SC, TS));
   end Time_Of;

end Ada.Execution_Time;
