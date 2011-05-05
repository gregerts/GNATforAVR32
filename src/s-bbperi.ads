------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                  S Y S T E M . B B . P E R I P H E R A L S               --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2006 The European Space Agency            --
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

--  This package defines constants and primitives used for handling the
--  peripherals available in the target board.

--  This is the AVR32 version of this package.

pragma Restrictions (No_Elaboration_Code);

with System.BB.Parameters;
--  Used for Clock_Frequency
--           Main_Clock_Multiply
--           Main_Clock_Divsion
--           Peripheral_Division

with System.BB.Interrupts;
--  Used for Interrupt_ID
--           Interrupt_Level

package System.BB.Peripherals is

   pragma Preelaborate;

   package SBP renames System.BB.Parameters;
   package SBI renames System.BB.Interrupts;

   -----------------------------
   -- Hardware initialization --
   -----------------------------

   procedure Initialize_Board;
   --  Procedure that performs the hardware initialization of the board.
   --  Should be called before any other operations in this package.

   -----------------------
   -- Board frequencies --
   -----------------------

   Main_Clock_Frequency : constant :=
     (SBP.Clock_Frequency * SBP.Clock_Multiplication * 10 ** 6);
   --  Frequency of main clock in Hz

   Peripheral_Frequency : constant :=
     Main_Clock_Frequency / SBP.Peripheral_Division;
   --  Frequency of peripheral clock in Hz

   ------------------------------------
   -- TMU definitions and primitives --
   ------------------------------------

   TMU_Frequency : constant := Peripheral_Frequency;

   type TMU_Interval is mod 2 ** 64;
   for TMU_Interval'Size use 64;

   procedure Set_Compare (Compare : TMU_Interval);
   pragma Inline (Set_Compare);

   procedure Set_Count (Count : TMU_Interval);
   pragma Inline (Set_Count);

   procedure Swap_Context (Compare_A : TMU_Interval;
                           Count_A   : TMU_Interval;
                           Count_B   : out TMU_Interval);
   pragma Inline (Swap_Context);

   function Get_Count return TMU_Interval;
   pragma Inline (Get_Count);

   ----------------
   -- Interrupts --
   ----------------

   function To_Level
     (Interrupt : SBI.Interrupt_ID) return SBI.Interrupt_Level;
   --  Function returning the level of an interrupt ID.

   --  Constants defining the external interrupts

   TMU     : constant := 59; --  Group 19
   SDRAMC  : constant := 58; --  Group 18
   USB     : constant := 57; --  Group 17
   MACB    : constant := 56; --  Group 16
   ADC     : constant := 55; --  Group 15
   TC_2    : constant := 54; --  Group 14
   TC_1    : constant := 53;
   TC_0    : constant := 52;
   SSC     : constant := 51; --  Group 13
   PWM     : constant := 50; --  Group 12
   TWI     : constant := 49; --  Group 11
   SPI_1   : constant := 48; --  Group 10
   SPI_0   : constant := 47; --  Group 9
   USART_3 : constant := 46; --  Group 8
   USART_2 : constant := 45; --  Group 7
   USART_1 : constant := 44; --  Group 6
   USART_0 : constant := 43; --  Group 5
   FLASHC  : constant := 42; --  Group 4
   PDCA_14 : constant := 41; --  Group 3
   PDCA_13 : constant := 40;
   PDCA_12 : constant := 39;
   PDCA_11 : constant := 38;
   PDCA_10 : constant := 37;
   PDCA_9  : constant := 36;
   PDCA_8  : constant := 35;
   PDCA_7  : constant := 34;
   PDCA_6  : constant := 33;
   PDCA_5  : constant := 32;
   PDCA_4  : constant := 31;
   PDCA_3  : constant := 30;
   PDCA_2  : constant := 29;
   PDCA_1  : constant := 28;
   PDCA_0  : constant := 27;
   GPIO_13 : constant := 26; --  Group 2
   GPIO_12 : constant := 25;
   GPIO_11 : constant := 24;
   GPIO_10 : constant := 23;
   GPIO_9  : constant := 22;
   GPIO_8  : constant := 21;
   GPIO_7  : constant := 20;
   GPIO_6  : constant := 19;
   GPIO_5  : constant := 18;
   GPIO_4  : constant := 17;
   GPIO_3  : constant := 16;
   GPIO_2  : constant := 15;
   GPIO_1  : constant := 14;
   GPIO_0  : constant := 13;
   FREQM   : constant := 12; --  Group 1
   PM      : constant := 11;
   RTC     : constant := 10;
   EIM_7   : constant := 9;
   EIM_6   : constant := 8;
   EIM_5   : constant := 7;
   EIM_4   : constant := 6;
   EIM_3   : constant := 5;
   EIM_2   : constant := 4;
   EIM_1   : constant := 3;
   EIM_0   : constant := 2;
   COMPARE : constant := 1;  --  Group 0

   --------------------
   -- Output Console --
   --------------------

   procedure Initialize_Console;
   --  Initialize the USART to be used as output console

   procedure Console_Send (Char : Character);
   pragma Inline (Console_Send);
   --  Procedure to send Characters to the USART used as output console

end System.BB.Peripherals;
