------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--               S Y S T E M . B B . C P U _ P R I M I T I V E S            --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2004 The European Space Agency            --
--                     Copyright (C) 2003-2007, AdaCore                     --
--             Copyright (C) 2007-2008 Kristoffer N. Gregertsen             --
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
-- The porting of GNARL to bare board  targets was initially  developed  by --
-- the Real-Time Systems Group at the Technical University of Madrid.       --
--                                                                          --
------------------------------------------------------------------------------

--  This package contains the primitives which are dependent of the
--  underlying processor.

--  This is the AVR32 version of this package.

pragma Restrictions (No_Elaboration_Code);

with System;
--  Used for Address
--           Any_Priority

with System.Parameters;
--  Used for Size_Type

with System.BB.Parameters;
--  Used for Range_of_Vector

with System.BB.Interrupts;
--  Used for Interrupt_Level

package System.BB.CPU_Primitives is

   pragma Preelaborate;

   ----------
   -- Word --
   ----------
   type Word is mod 2 ** System.Word_Size;
   for Word'Size use System.Word_Size;

   ------------------------
   -- Context management --
   ------------------------

   Context_Buffer_Capacity : constant := 12;
   --  The task context is stored in the following order:
   --
   --     R12 | SR | PC | SP | R7 | R6 | R5 | R4 | R3 | R2 | R1 | R0

   Context_Buffer_Size : constant :=
     Context_Buffer_Capacity * System.Word_Size;
   --  Size calculated taken into account that the components are 32-bit.

   type Context_Buffer is private;
   --  This type contains the saved register set for each thread

   procedure Context_Switch;
   pragma Import (Asm, Context_Switch, "context_switch");
   --  Perform the context switch between the running_thread and the
   --  first_thread.

   procedure Initialize_Context
     (Buffer          : not null access Context_Buffer;
      Program_Counter : System.Address;
      Argument        : System.Address;
      Stack_Pointer   : System.Address);
   pragma Inline (Initialize_Context);
   --  Initialize_Context inserts inside the context buffer the
   --  default values for each register. The values for the stack
   --  pointer, the program counter, and argument to be passed
   --  are provided as arguments.

   ---------------------------------
   -- Interrupt and trap handling --
   ---------------------------------

   procedure Disable_Interrupts;
   pragma Inline_Always (Disable_Interrupts);
   --  All external interrupts are masked (except NMI).

   procedure Restore_Interrupts;
   pragma Inline_Always (Restore_Interrupts);
   --  External interrupt mask is restored.

   procedure Enable_Interrupts
     (Level : System.BB.Interrupts.Interrupt_Level);
   pragma Inline_Always (Enable_Interrupts);
   --  Interrupts are unmasked if they are above the value given by Level

   ------------------------------
   -- COUNT / COMPARE handling --
   ------------------------------

   function Get_Count return Word;
   pragma Inline_Always (Get_Count);

   procedure Adjust_Compare (Compare : Word);
   pragma Inline_Always (Adjust_Compare);

   procedure Reset_Count (Compare : Word);
   pragma Inline_Always (Reset_Count);

   procedure Swap_Count
     (Compare : Word;
      Count   : out Word);
   pragma Inline_Always (Swap_Count);

private

   subtype Range_Of_Context is Natural range 0 .. Context_Buffer_Capacity - 1;
   --  Type used for accessing to the different elements in the context buffer

   type Context_Buffer is array (Range_Of_Context) of System.Address;
   for Context_Buffer'Size use Context_Buffer_Size;
   pragma Suppress_Initialization (Context_Buffer);
   --  This array contains all the registers that the thread needs to save
   --  within its thread descriptor.

end System.BB.CPU_Primitives;
