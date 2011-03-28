------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--      S Y S T E M . B B . P E R I P H E R A L S . R E G I S T E R S       --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2006 The European Space Agency            --
--                     Copyright (C) 2003-2007, AdaCore                     --
--              Copyright (C) 2007-2008 Kristoffer N. Gregertsen            --
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

--  This package provides the appropriate mapping for the system registers.
--  This is the AVR32 version of this package.

pragma Restrictions (No_Elaboration_Code);

package System.BB.Peripherals.Registers is

   pragma Preelaborate;

   ----------------------------
   -- Local type definitions --
   ----------------------------

   type Scaler_1 is mod 2;
   for Scaler_1'Size use 1;

   type Scaler_2 is mod 2 ** 2;
   for Scaler_2'Size use 2;

   type Scaler_3 is mod 2 ** 3;
   for Scaler_3'Size use 3;

   type Scaler_4 is mod 2 ** 4;
   for Scaler_4'Size use 4;

   type Scaler_5 is mod 2 ** 5;
   for Scaler_5'Size use 5;

   type Scaler_6 is mod 2 ** 6;
   for Scaler_6'Size use 6;

   type Scaler_7 is mod 2 ** 7;
   for Scaler_7'Size use 7;

   type Scaler_8 is mod 2 ** 8;
   for Scaler_8'Size use 8;

   type Scaler_10 is mod 2 ** 10;
   for Scaler_10'Size use 10;

   type Scaler_12 is mod 2 ** 12;
   for Scaler_12'Size use 12;

   type Scaler_14 is mod 2 ** 14;
   for Scaler_14'Size use 14;

   type Scaler_16 is mod 2 ** 16;
   for Scaler_16'Size use 16;

   type Scaler_24 is mod 2 ** 24;
   for Scaler_24'Size use 24;

   type Scaler_32 is mod 2 ** 32;
   for Scaler_32'Size use 32;

   --------------------------------------------
   --  Addresses of memory mapped registers  --
   --------------------------------------------

   Flash_Address :
     constant System.Address := System'To_Address (16#FFFE1400#);

   Interrupt_Controller_Address :
     constant System.Address := System'To_Address (16#FFFF0800#);

   Interrupt_Priority_Address :
     constant System.Address := System'To_Address (16#FFFF0800#);

   Interrupt_Request_Address :
     constant System.Address := System'To_Address (16#FFFF0800# + 256);

   Power_Manager_Address :
     constant System.Address := System'To_Address (16#FFFF0C00#);

   GPIO_Port_A_Address :
     constant System.Address := System'To_Address (16#FFFF1000#);

   GPIO_Port_B_Address :
     constant System.Address := System'To_Address (16#FFFF1100#);

   USART_Channel_0_Address :
     constant System.Address := System'To_Address (16#FFFF1400#);

   USART_Channel_1_Address :
     constant System.Address := System'To_Address (16#FFFF1800#);

   ---------------------------------
   -- Main Clock Control Register --
   ---------------------------------

   type Main_Clock_Control_Register is
      record
         Clock_Select : Scaler_2  := 0;
         Enable_Osc_0 : Boolean   := False;
         Enable_Osc_1 : Boolean   := False;
         Unused_A     : Scaler_12 := 0;
         Unused_B     : Scaler_16 := 0;
      end record;

   for Main_Clock_Control_Register use
      record
         Clock_Select at 0 range 30 .. 31;
         Enable_Osc_0 at 0 range 29 .. 29;
         Enable_Osc_1 at 0 range 28 .. 28;
         Unused_A     at 0 range 16 .. 27;
         Unused_B     at 0 range 0 .. 15;
      end record;

   for Main_Clock_Control_Register'Size use 32;

   pragma Suppress_Initialization (Main_Clock_Control_Register);

   ---------------------------
   -- Clock Select Register --
   ---------------------------

   type Clock_Select_Register is
      record
         CPU_Select : Scaler_3 := 0;
         Unused_A   : Scaler_4 := 0;
         CPU_Div    : Boolean  := False;

         HSB_Select : Scaler_3 := 0;
         Unused_B   : Scaler_4 := 0;
         HSB_Div    : Boolean  := False;

         PBA_Select : Scaler_3 := 0;
         Unused_C   : Scaler_4 := 0;
         PBA_Div    : Boolean  := False;

         PBB_Select : Scaler_3 := 0;
         Unused_D   : Scaler_4 := 0;
         PBB_Div    : Boolean  := False;
      end record;

   for Clock_Select_Register use
      record
         CPU_Select at 0 range 29 .. 31;
         Unused_A   at 0 range 25 .. 28;
         CPU_Div    at 0 range 24 .. 24;

         HSB_Select at 0 range 21 .. 23;
         Unused_B   at 0 range 17 .. 20;
         HSB_Div    at 0 range 16 .. 16;

         PBA_Select at 0 range 13 .. 15;
         Unused_C   at 0 range 9 .. 12;
         PBA_Div    at 0 range 8 .. 8;

         PBB_Select at 0 range 5 .. 7;
         Unused_D   at 0 range 1 .. 4;
         PBB_Div    at 0 range 0 .. 0;
      end record;

   for Clock_Select_Register'Size use 32;

   pragma Suppress_Initialization (Clock_Select_Register);

   --------------------------
   -- PPL Control Register --
   --------------------------

   type PPL_Control_Register is
      record
         Enable   : Boolean  := False;
         Osc      : Scaler_1 := 0;
         Options  : Scaler_3 := 0;
         Unused_A : Scaler_3 := 0;
         Div      : Scaler_4 := 0;
         Unused_B : Scaler_4 := 0;
         Mult     : Scaler_4 := 0;
         Unused_C : Scaler_4 := 0;
         Count    : Scaler_6 := 0;
         Unused_D : Scaler_2 := 0;
      end record;

   for PPL_Control_Register use
      record
         Enable    at 0 range 31 .. 31;
         Osc       at 0 range 30 .. 30;
         Options   at 0 range 27 .. 29;
         Unused_A  at 0 range 24 .. 26;
         Div       at 0 range 20 .. 23;
         Unused_B  at 0 range 16 .. 19;
         Mult      at 0 range 12 .. 15;
         Unused_C  at 0 range 8 .. 11;
         Count     at 0 range 2 .. 7;
         Unused_D  at 0 range 0 .. 1;
      end record;

   for PPL_Control_Register'Size use 32;

   pragma Suppress_Initialization (PPL_Control_Register);

   --------------------------
   -- Osc Control Register --
   --------------------------

   type Osc_Control_Register is
      record
         Mode       : Scaler_3  := 0;
         Unused_A   : Scaler_5  := 0;
         Startup    : Scaler_3  := 0;
         Unused_B   : Scaler_5  := 0;
         Unused_C   : Scaler_16 := 0;
      end record;

   for Osc_Control_Register use
      record
         Mode       at 0 range 29 .. 31;
         Unused_A   at 0 range 24 .. 28;
         Startup    at 0 range 21 .. 23;
         Unused_B   at 0 range 16 .. 20;
         Unused_C   at 0 range 0 .. 15;
      end record;

   for Osc_Control_Register'Size use 32;

   pragma Suppress_Initialization (Osc_Control_Register);

   -------------------------
   -- Osc Status Register --
   -------------------------

   type Osc_Status_Register is
      record
         Lock_PPL_0   : Boolean   := False;
         Lock_PPL_1   : Boolean   := False;
         Unused_A     : Scaler_3  := 0;
         Clock_Ready  : Boolean   := False;
         Mask_Ready   : Boolean   := False;
         Osc_0_Ready  : Boolean   := False;
         Osc_1_Ready  : Boolean   := False;
         Osc_32_Ready : Boolean   := False;
         Unused_B     : Scaler_6  := 0;
         Unused_C     : Scaler_16 := 0;
      end record;

   for Osc_Status_Register use
      record
         Lock_PPL_0   at 0 range 31 .. 31;
         Lock_PPL_1   at 0 range 30 .. 30;
         Unused_A     at 0 range 27 .. 29;
         Clock_Ready  at 0 range 26 .. 26;
         Mask_Ready   at 0 range 25 .. 25;
         Osc_0_Ready  at 0 range 24 .. 24;
         Osc_1_Ready  at 0 range 23 .. 23;
         Osc_32_Ready at 0 range 22 .. 22;
         Unused_B     at 0 range 16 .. 21;
         Unused_C     at 0 range 0 .. 15;
      end record;

   for Osc_Status_Register'Size use 32;

   pragma Suppress_Initialization (Osc_Status_Register);

   -----------------------------
   -- Power Manager Interface --
   -----------------------------

   type Power_Manager_Interface is
      record
         Main              : Main_Clock_Control_Register;
         Clock_Select      : Clock_Select_Register;
         CPU_Mask          : Scaler_32;
         HSB_Mask          : Scaler_32;
         PBA_Mask          : Scaler_32;
         PBB_Mask          : Scaler_32;
         Unused_A          : Scaler_32;
         Unused_B          : Scaler_32;
         PPL_0             : PPL_Control_Register;
         PPL_1             : PPL_Control_Register;
         Osc_0             : Osc_Control_Register;
         Osc_1             : Osc_Control_Register;
         Unused_C          : Scaler_32;
         Unused_D          : Scaler_32;
         Unused_E          : Scaler_32;
         Unused_F          : Scaler_32;
         Interrupt_Enable  : Scaler_32;
         Interrupt_Disable : Scaler_32;
         Interrupt_Mask    : Scaler_32;
         Interrupt_Status  : Scaler_32;
         Interrupt_Clear   : Scaler_32;
         Status            : Osc_Status_Register;
         pragma Atomic (Main);
         pragma Atomic (Clock_Select);
         pragma Atomic (CPU_Mask);
         pragma Atomic (HSB_Mask);
         pragma Atomic (PBA_Mask);
         pragma Atomic (PBB_Mask);
         pragma Atomic (PPL_0);
         pragma Atomic (PPL_1);
         pragma Atomic (Osc_0);
         pragma Atomic (Osc_1);
         pragma Atomic (Interrupt_Enable);
         pragma Atomic (Interrupt_Disable);
         pragma Atomic (Interrupt_Mask);
         pragma Atomic (Interrupt_Status);
         pragma Atomic (Interrupt_Clear);
         pragma Atomic (Status);
      end record;

   pragma Suppress_Initialization (Power_Manager_Interface);

   ----------------------------
   -- Flash Control Register --
   ----------------------------

   type Flash_Control_Register is
      record
         Unused_A   : Scaler_6  := 0;
         Wait_State : Boolean   := False;
         Unused_B   : Scaler_1  := 0;
         Unused_C   : Scaler_24 := 0;
      end record;

   for Flash_Control_Register use
      record
         Unused_A   at 0 range 26 .. 31;
         Wait_State at 0 range 25 .. 25;
         Unused_B   at 0 range 24 .. 24;
         Unused_C   at 0 range 0 .. 23;
      end record;

   for Flash_Control_Register'Size use 32;

   pragma Suppress_Initialization (Flash_Control_Register);

   ---------------------
   -- Flash interface --
   ---------------------

   type Flash_Interface is
      record
         Control : Flash_Control_Register;
         pragma Atomic (Control);
      end record;

   pragma Suppress_Initialization (Flash_Interface);

   --------------------------------
   -- Interrupt Request Register --
   --------------------------------

   subtype Interrupt_Request_Register is Scaler_32;

   -----------------------------
   -- Interrupt Request Array --
   -----------------------------

   type Interrupt_Request_Array is
     array (0 .. 63) of Interrupt_Request_Register;

   pragma Atomic_Components (Interrupt_Request_Array);
   pragma Suppress_Initialization (Interrupt_Request_Array);

   ---------------------------------
   -- Interrupt Priority Register --
   ---------------------------------

   type Interrupt_Priority_Register is
      record
         Autovector : Scaler_14 := 0;
         Unused     : Scaler_16 := 0;
         Level      : Scaler_2  := 0;
      end record;

   for Interrupt_Priority_Register use
      record
         Autovector at 0 range 18 .. 31;
         Unused     at 0 range 2 .. 17;
         Level      at 0 range 0 .. 1;
      end record;

   for Interrupt_Priority_Register'Size use 32;

   pragma Suppress_Initialization (Interrupt_Priority_Register);

   ------------------------------
   -- Interrupt Priority Array --
   ------------------------------

   type Interrupt_Priority_Array is
     array (0 .. 63) of Interrupt_Priority_Register;

   pragma Atomic_Components (Interrupt_Priority_Array);
   pragma Suppress_Initialization (Interrupt_Priority_Array);

   ----------------------------
   -- USART Control Register --
   ----------------------------

   type USART_Control_Register is
      record
         Unused_A   : Scaler_2  := 0;
         Reset_RX   : Boolean   := False;
         Reset_TX   : Boolean   := False;
         Enable_RX  : Boolean   := False;
         Disable_RX : Boolean   := False;
         Enable_TX  : Boolean   := False;
         Disable_TX : Boolean   := False;
         Unused_B   : Scaler_24 := 0;
      end record;

   for USART_Control_Register use
      record
         Unused_A   at 0 range 30 .. 31;
         Reset_RX   at 0 range 29 .. 29;
         Reset_TX   at 0 range 28 .. 28;
         Enable_RX  at 0 range 27 .. 27;
         Disable_RX at 0 range 26 .. 26;
         Enable_TX  at 0 range 25 .. 25;
         Disable_TX at 0 range 24 .. 24;
         Unused_B   at 0 range 0 .. 23;
      end record;

   for USART_Control_Register'Size use 32;

   pragma Suppress_Initialization (USART_Control_Register);

   -------------------------
   -- USART Mode Register --
   -------------------------

   type USART_Mode_Register is
      record
         Mode         : Scaler_4  := 0;
         Clock_Select : Scaler_2  := 0;
         Charlength   : Scaler_2  := 0;
         Synchronous  : Boolean   := False;
         Parity       : Scaler_3  := 0;
         Stopbits     : Scaler_2  := 0;
         Channel_Mode : Scaler_2  := 0;
         Bit_Order    : Boolean   := False;
         Charlength_9 : Boolean   := False;
         Clock_Output : Boolean   := False;
         Oversampling : Boolean   := False;
         Unused       : Scaler_12 := 0;
      end record;

   for USART_Mode_Register use
      record
         Mode         at 0 range 28 .. 31;
         Clock_Select at 0 range 26 .. 27;
         Charlength   at 0 range 24 .. 25;
         Synchronous  at 0 range 23 .. 23;
         Parity       at 0 range 20 .. 22;
         Stopbits     at 0 range 18 .. 19;
         Channel_Mode at 0 range 16 .. 17;
         Bit_Order    at 0 range 15 .. 15;
         Charlength_9 at 0 range 14 .. 14;
         Clock_Output at 0 range 13 .. 13;
         Oversampling at 0 range 12 .. 12;
         Unused       at 0 range 0 .. 11;
      end record;

   for USART_Mode_Register'Size use 32;

   pragma Suppress_Initialization (USART_Mode_Register);

   ---------------------------
   -- USART Status Register --
   ---------------------------

   type USART_Status_Register is
      record
         RX_Ready : Boolean;
         TX_Ready : Boolean;
         Unused_A : Scaler_6;
         Unused_B : Scaler_24;
      end record;

   for USART_Status_Register use
      record
         RX_Ready at 0 range 31 .. 31;
         TX_Ready at 0 range 30 .. 30;
         Unused_A at 0 range 24 .. 29;
         Unused_B at 0 range 0 .. 23;
      end record;

   for USART_Status_Register'Size use 32;

   pragma Suppress_Initialization (USART_Status_Register);

   ----------------------------
   -- USART Holding Register --
   ----------------------------

   type USART_Holding_Register is
      record
         Char   : Character;
         Unused : Scaler_24;
      end record;

   for USART_Holding_Register use
      record
         Char   at 0 range 24 .. 31;
         Unused at 0 range 0 .. 23;
      end record;

   for USART_Holding_Register'Size use 32;

   pragma Suppress_Initialization (USART_Holding_Register);

   ---------------------------------------
   -- USART Baudrate Generator Register --
   ---------------------------------------

   type USART_Baudrate_Register is
      record
         Clock_Divider   : Scaler_16 := 0;
         Fractional_Part : Scaler_3  := 0;
         Unused_A        : Scaler_5  := 0;
         Unused_B        : Scaler_8  := 0;
      end record;

   for USART_Baudrate_Register use
      record
         Clock_Divider   at 0 range 16 .. 31;
         Fractional_Part at 0 range 13 .. 15;
         Unused_A        at 0 range 8 .. 12;
         Unused_B        at 0 range 0 .. 7;
      end record;

   for USART_Baudrate_Register'Size use 32;

   pragma Suppress_Initialization (USART_Baudrate_Register);

   -----------------------------
   -- USART Channel Interface --
   -----------------------------

   type USART_Channel_Interface is
      record
         Control           : USART_Control_Register;
         Mode              : USART_Mode_Register;
         Interrupt_Enable  : Scaler_32;
         Interrupt_Disable : Scaler_32;
         Interrupt_Mask    : Scaler_32;
         Status            : USART_Status_Register;
         RX                : USART_Holding_Register;
         TX                : USART_Holding_Register;
         Baudrate          : USART_Baudrate_Register;
         pragma Atomic (Control);
         pragma Atomic (Mode);
         pragma Atomic (Interrupt_Enable);
         pragma Atomic (Interrupt_Disable);
         pragma Atomic (Interrupt_Mask);
         pragma Atomic (Status);
         pragma Atomic (RX);
         pragma Atomic (TX);
         pragma Atomic (Baudrate);
      end record;

   pragma Suppress_Initialization (USART_Channel_Interface);

   --------------------
   -- GPIO Pin Array --
   --------------------

   type GPIO_Pin_Array is array (0 .. 31) of Boolean;
   pragma Pack (GPIO_Pin_Array);
   for GPIO_Pin_Array'Size use 32;

   ---------------
   -- GPIO Mask --
   ---------------

   subtype GPIO_Mask is Scaler_32;

   ---------------------------
   -- GPIO Control Register --
   ---------------------------

   type GPIO_Control_Register is
      record
         RW     : GPIO_Pin_Array;
         Set    : GPIO_Mask;
         Clear  : GPIO_Mask;
         Toggle : GPIO_Mask;
         pragma Atomic (RW);
         pragma Atomic (Set);
         pragma Atomic (Clear);
         pragma Atomic (Toggle);
      end record;

   pragma Suppress_Initialization (GPIO_Control_Register);

   type GPIO_Port_Interface is
      record
         GPIO_Enable      : GPIO_Control_Register;
         Peripheral_Mux_0 : GPIO_Control_Register;
         Peripheral_Mux_1 : GPIO_Control_Register;
      end record;

   pragma Suppress_Initialization (GPIO_Port_Interface);

end System.BB.Peripherals.Registers;
