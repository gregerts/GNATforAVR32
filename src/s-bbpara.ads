------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                   S Y S T E M . B B . P A R A M E T E R S                --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
--                     Copyright (C) 2003-2007, AdaCore                     --
--             Copyright (C) 2007-2011, Kristoffer N. Gregertsen            --
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

--  This package defines basic parameters used by the low level tasking
--  system.

--  This is the AVR32 version of this package.

pragma Restrictions (No_Elaboration_Code);

package System.BB.Parameters is
   pragma Pure;

   ------------------------
   -- Memory definitions --
   ------------------------

   --  Memory space available in the board. This information is
   --  defined by the linker script file.

   Top_Of_Environment_Stack : constant System.Address;
   pragma Import (Asm, Top_Of_Environment_Stack, "_stack");
   --  Top of the stack to be used by the environment task

   Bottom_Of_Environment_Stack : constant System.Address;
   pragma Import (Asm, Bottom_Of_Environment_Stack, "_estack");
   --  Bottom of the stack to be used by the environment task

   --------------------
   -- Clock settings --
   --------------------

   Clock_Frequency : constant := 12;
   --  Frequency of the external clock in MHz.

   Clock_Multiplication : constant := 5;
   --  Multiplication of main clock to external clock.

   Peripheral_Division : constant := 1;
   --  Scaling of peripheral clocks relative to main clock.
   --  Possible divisions are 1, 2, 4, 8, 16, 32, 64, 128 and 256.

   Flash_Wait_State : constant := 1;
   --  Number of wait states in Flash. For AVR32 UC3 value 0 to
   --  disable and 1 to enable.

   ----------------
   -- Interrupts --
   ----------------

   Interrupt_Levels : constant := 4;
   --  Number of interrupt levels in the AVR32 architecture.

   Interrupt_Groups : constant := 19;
   --  Number of interrupt groups on the UC3A.

   Interrupts : constant := 58;
   --  The number of interrupts on the UC3A

   Interrupt_Clocks : constant := 10;
   --  Maximal number of interrupt timers and thereby also interrupts

   -------------------------
   -- USART I / 0 channel --
   -------------------------

   USART_Baudrate : constant := 115200;

   ------------
   -- Stacks --
   ------------

   Interrupt_Stack_Size : constant := 2 * 1024;  --  bytes
   --  Size of each of the interrupt stacks

end System.BB.Parameters;
