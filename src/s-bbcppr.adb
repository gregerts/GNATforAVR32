------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--               S Y S T E M . B B . C P U _ P R I M I T I V E S            --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
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

--  This is the AVR32 version of this package.

pragma Restrictions (No_Elaboration_Code);

with System.Machine_Code;
--  Used for inline ASM

with System.Storage_Elements;
--  Used for Integer_Address
--           To_Address
--           To_Integer

with Interfaces;
--  Used for Unsigned_32
--           Shift_Left

package body System.BB.CPU_Primitives is

   package SMC renames System.Machine_Code;
   package SSE renames System.Storage_Elements;

   use type SSE.Integer_Address;
   use type SSE.Storage_Offset;

   procedure Trampoline;
   pragma Import (Asm, Trampoline, "trampoline");

   ----------------
   -- Local data --
   ----------------

   SR  : constant Range_Of_Context := 0;
   PC  : constant Range_Of_Context := 1;
   SP  : constant Range_Of_Context := 2;
   R0  : constant Range_Of_Context := 10;
   R1  : constant Range_Of_Context := 9;

   ------------------------
   -- Initialize_Context --
   ------------------------

   procedure Initialize_Context
     (Buffer          : not null access Context_Buffer;
      Program_Counter : System.Address;
      Argument        : System.Address;
      Stack_Pointer   : System.Address)
   is
      --  The stack must be aligned to 32
      Aligned_SP : constant System.Address :=
        SSE.To_Address ((SSE.To_Integer (Stack_Pointer) / 32) * 32);
   begin

      --  Initialize context of task
      Buffer (SR)  := SSE.To_Address (16#0041_0000#);
      Buffer (PC)  := Trampoline'Address;
      Buffer (SP)  := Aligned_SP;
      Buffer (R0)  := Program_Counter;
      Buffer (R1)  := Argument;

   end Initialize_Context;

   ------------------------
   -- Disable_Interrupts --
   ------------------------

   procedure Disable_Interrupts is
   begin
      SMC.Asm ("ssrf    16"     & ASCII.LF & ASCII.HT &
               "nop"            & ASCII.LF & ASCII.HT &
               "nop",
               Clobber => "memory",
               Volatile => True);
   end Disable_Interrupts;

   ------------------------
   -- Restore_Interrupts --
   ------------------------

   procedure Restore_Interrupts is
   begin
      SMC.Asm ("csrf    16",
               Clobber => "memory",
               Volatile => True);
   end Restore_Interrupts;

   ----------------------
   -- Enable_Interrupt --
   ----------------------

   procedure Enable_Interrupts
     (Level : System.BB.Interrupts.Interrupt_Level)
   is
      use Interfaces;
      Mask : constant Unsigned_32 := Shift_Left (2, Integer (Level)) - 2;
   begin
      SMC.Asm ("mfsr    r8, 0"         & ASCII.LF & ASCII.HT &
               "bfins   r8, %0, 16, 5" & ASCII.LF & ASCII.HT &
               "mtsr    0, r8"         & ASCII.LF & ASCII.HT &
               "nop"                   & ASCII.LF & ASCII.HT &
               "nop",
               Inputs => Unsigned_32'Asm_Input ("r", Mask),
               Clobber => "r8, cc, memory",
               Volatile => True);
   end Enable_Interrupts;

   -------------------------
   -- Wait_For_Interrupts --
   -------------------------

   procedure Wait_For_Interrupts is
      use Interfaces;
      Mask : constant Unsigned_32 := 0;
   begin
      SMC.Asm ("mfsr    r8, 0"         & ASCII.LF & ASCII.HT &
               "bfins   r8, %0, 16, 5" & ASCII.LF & ASCII.HT &
               "mtsr    0, r8"         & ASCII.LF & ASCII.HT &
               "sleep   0"             & ASCII.LF & ASCII.HT &
               "ssrf    16"            & ASCII.LF & ASCII.HT &
               "nop"                   & ASCII.LF & ASCII.HT &
               "nop",
               Inputs => Unsigned_32'Asm_Input ("r", Mask),
               Clobber => "r8, cc, memory",
               Volatile => True);
   end Wait_For_Interrupts;

   ---------------
   -- Get_Count --
   ---------------

   function Get_Count return Word is
      Count : Word;
   begin
      SMC.Asm ("mfsr    %0, 264",
               Outputs => Word'Asm_Output ("=r", Count),
               Volatile => True);

      return Count;
   end Get_Count;

   --------------------
   -- Adjust_Compare --
   --------------------

   procedure Adjust_Compare (Compare : Word) is
   begin

      SMC.Asm ("mfsr    r8, 264" & ASCII.LF & ASCII.HT &
               "sub     r8, -8"  & ASCII.LF & ASCII.HT &
               "cp.w    r8, %0"  & ASCII.LF & ASCII.HT &
               "movlo   r8, %0"  & ASCII.LF & ASCII.HT &
               "mtsr    268, r8",
               Inputs => Word'Asm_Input ("r", Compare),
               Clobber => "r8, cc",
               Volatile => True);

   end Adjust_Compare;

   ----------------
   -- Reset_Count --
   ----------------

   procedure Reset_Count (Compare : Word) is
      Count : constant Word := 0;
   begin

      SMC.Asm ("mtsr    264, %0" & ASCII.LF & ASCII.HT &
               "mtsr    268, %0" & ASCII.LF & ASCII.HT &
               "mtsr    264, %1",
               Inputs => (Word'Asm_Input ("r", Compare),
                          Word'Asm_Input ("r", Count)),
               Volatile => True);

   end Reset_Count;

   ----------------
   -- Swap_Count --
   ----------------

   procedure Swap_Count
     (Compare : Word;
      Count   : out Word)
   is
      New_Count : constant Word := 0;
      Old_Count : Word;
   begin

      SMC.Asm ("mfsr    r8, 264" & ASCII.LF & ASCII.HT &
               "mtsr    264, %1" & ASCII.LF & ASCII.HT &
               "mtsr    268, %1" & ASCII.LF & ASCII.HT &
               "mtsr    264, %2" & ASCII.LF & ASCII.HT &
               "mov     %0, r8",
               Inputs => (Word'Asm_Input ("r", Compare),
                          Word'Asm_Input ("r", New_Count)),
               Outputs => Word'Asm_Output ("=r", Old_Count),
               Clobber => "r8");

      Count := Old_Count + 4;

   end Swap_Count;

end System.BB.CPU_Primitives;
