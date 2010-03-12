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

   type Scaler_32 is mod 2 ** 32;
   for Scaler_32'Size use 32;

   type Reserved_1 is array (0 .. 0) of Boolean;
   for Reserved_1'Size use 1;
   pragma Pack (Reserved_1);

   type Reserved_2 is array (0 .. 1) of Boolean;
   for Reserved_2'Size use 2;
   pragma Pack (Reserved_2);

   type Reserved_3 is array (0 .. 2) of Boolean;
   for Reserved_3'Size use 3;
   pragma Pack (Reserved_3);

   type Reserved_4 is array (0 .. 3) of Boolean;
   for Reserved_4'Size use 4;
   pragma Pack (Reserved_4);

   type Reserved_5 is array (0 .. 4) of Boolean;
   for Reserved_5'Size use 5;
   pragma Pack (Reserved_5);

   type Reserved_7 is array (0 .. 6) of Boolean;
   for Reserved_7'Size use 7;
   pragma Pack (Reserved_7);

   type Reserved_8 is array (0 .. 7) of Boolean;
   for Reserved_8'Size use 8;
   pragma Pack (Reserved_8);

   type Reserved_12 is array (0 .. 11) of Boolean;
   for Reserved_12'Size use 12;
   pragma Pack (Reserved_12);

   type Reserved_13 is array (0 .. 12) of Boolean;
   for Reserved_13'Size use 13;
   pragma Pack (Reserved_13);

   type Reserved_16 is array (0 .. 15) of Boolean;
   for Reserved_16'Size use 16;
   pragma Pack (Reserved_16);

   type Reserved_20 is array (0 .. 19) of Boolean;
   for Reserved_20'Size use 20;
   pragma Pack (Reserved_20);

   type Reserved_21 is array (0 .. 20) of Boolean;
   for Reserved_21'Size use 21;
   pragma Pack (Reserved_21);

   type Reserved_22 is array (0 .. 21) of Boolean;
   for Reserved_22'Size use 22;
   pragma Pack (Reserved_22);

   type Reserved_23 is array (0 .. 22) of Boolean;
   for Reserved_23'Size use 23;
   pragma Pack (Reserved_23);

   type Reserved_24 is array (0 .. 23) of Boolean;
   for Reserved_24'Size use 24;
   pragma Pack (Reserved_24);

   type Reserved_25 is array (0 .. 24) of Boolean;
   for Reserved_25'Size use 25;
   pragma Pack (Reserved_25);

   type Reserved_26 is array (0 .. 25) of Boolean;
   for Reserved_26'Size use 26;
   pragma Pack (Reserved_26);

   type Reserved_28 is array (0 .. 27) of Boolean;
   for Reserved_28'Size use 28;
   pragma Pack (Reserved_28);

   type Reserved_29 is array (0 .. 28) of Boolean;
   for Reserved_29'Size use 29;
   pragma Pack (Reserved_29);

   type Reserved_30 is array (0 .. 29) of Boolean;
   for Reserved_30'Size use 30;
   pragma Pack (Reserved_30);

   type Reserved_31 is array (0 .. 30) of Boolean;
   for Reserved_31'Size use 31;
   pragma Pack (Reserved_31);

   type Reserved_32 is array (0 .. 31) of Boolean;
   for Reserved_32'Size use 32;
   pragma Pack (Reserved_32);

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

   Interrupt_Cause_Address :
     constant System.Address := System'To_Address (16#FFFF0800# + 512);

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

   Timer_Counter_0_Address :
     constant System.Address := System'To_Address (16#FFFF3800#);

   Timer_Counter_1_Address :
     constant System.Address := System'To_Address (16#FFFF3840#);

   Timer_Counter_2_Address :
     constant System.Address := System'To_Address (16#FFFF3880#);

   ---------------------------------
   -- Main Clock Control Register --
   ---------------------------------

   type Main_Clock_Control_Register is
      record
         Main_Clock_Select   : Scaler_2;
         Enable_Oscillator_0 : Boolean;
         Enable_Oscillator_1 : Boolean;
         Reserved            : Reserved_28;
      end record;

   for Main_Clock_Control_Register use
      record
         Main_Clock_Select   at 0 range 30 .. 31;
         Enable_Oscillator_0 at 0 range 29 .. 29;
         Enable_Oscillator_1 at 0 range 28 .. 28;
         Reserved            at 0 range 0 .. 27;
      end record;

   for Main_Clock_Control_Register'Size use 32;

   pragma Suppress_Initialization (Main_Clock_Control_Register);

   ---------------------------
   -- Clock Select Register --
   ---------------------------

   type Clock_Select_Register is
      record
         CPU_Select : Scaler_3;
         Reserved_A : Reserved_4;
         CPU_Divide : Boolean;

         HSB_Select : Scaler_3;
         Reserved_B : Reserved_4;
         HSB_Divide : Boolean;

         PBA_Select : Scaler_3;
         Reserved_C : Reserved_4;
         PBA_Divide : Boolean;

         PBB_Select : Scaler_3;
         Reserved_D : Reserved_4;
         PBB_Divide : Boolean;
      end record;

   for Clock_Select_Register use
      record
         CPU_Select at 0 range 29 .. 31;
         Reserved_A at 0 range 25 .. 28;
         CPU_Divide at 0 range 24 .. 24;

         HSB_Select at 0 range 21 .. 23;
         Reserved_B at 0 range 17 .. 20;
         HSB_Divide at 0 range 16 .. 16;

         PBA_Select at 0 range 13 .. 15;
         Reserved_C at 0 range 9 .. 12;
         PBA_Divide at 0 range 8 .. 8;

         PBB_Select at 0 range 5 .. 7;
         Reserved_D at 0 range 1 .. 4;
         PBB_Divide at 0 range 0 .. 0;
      end record;

   for Clock_Select_Register'Size use 32;

   pragma Suppress_Initialization (Clock_Select_Register);

   ---------------------------------
   -- Oscillator Control Register --
   ---------------------------------

   type PPL_Control_Register is
      record
         Enable         : Boolean;
         Oscillator     : Scaler_1;
         Options        : Scaler_3;
         Reserved_A     : Reserved_3;
         Division       : Scaler_4;
         Reserved_B     : Reserved_4;
         Multiplication : Scaler_4;
         Reserved_C     : Reserved_4;
         Count          : Scaler_6;
         Reserved_D     : Reserved_2;
      end record;

   for PPL_Control_Register use
      record
         Enable         at 0 range 31 .. 31;
         Oscillator     at 0 range 30 .. 30;
         Options        at 0 range 27 .. 29;
         Reserved_A     at 0 range 24 .. 26;
         Division       at 0 range 20 .. 23;
         Reserved_B     at 0 range 16 .. 19;
         Multiplication at 0 range 12 .. 15;
         Reserved_C     at 0 range 8 .. 11;
         Count          at 0 range 2 .. 7;
         Reserved_D     at 0 range 0 .. 1;
      end record;

   for PPL_Control_Register'Size use 32;

   pragma Suppress_Initialization (PPL_Control_Register);

   ---------------------------------
   -- Oscillator Control Register --
   ---------------------------------

   type Oscillator_Control_Register is
      record
         Mode       : Scaler_3;
         Reserved_A : Reserved_5;
         Startup    : Scaler_3;
         Reserved_B : Reserved_21;
      end record;

   for Oscillator_Control_Register use
      record
         Mode       at 0 range 29 .. 31;
         Reserved_A at 0 range 24 .. 28;
         Startup    at 0 range 21 .. 23;
         Reserved_B at 0 range 0 .. 20;
      end record;

   for Oscillator_Control_Register'Size use 32;

   pragma Suppress_Initialization (Oscillator_Control_Register);

   --------------------------------
   -- Oscillator Status Register --
   --------------------------------

   type Oscillator_Status_Register is
      record
         Lock_PPL_0          : Boolean;
         Lock_PPL_1          : Boolean;
         Reserved_A          : Reserved_3;
         Clock_Ready         : Boolean;
         Mask_Ready          : Boolean;
         Oscillator_0_Ready  : Boolean;
         Oscillator_1_Ready  : Boolean;
         Oscillator_32_Ready : Boolean;
         Reserved_B          : Reserved_22;
      end record;

   for Oscillator_Status_Register use
      record
         Lock_PPL_0          at 0 range 31 .. 31;
         Lock_PPL_1          at 0 range 30 .. 30;
         Reserved_A          at 0 range 27 .. 29;
         Clock_Ready         at 0 range 26 .. 26;
         Mask_Ready          at 0 range 25 .. 25;
         Oscillator_0_Ready  at 0 range 24 .. 24;
         Oscillator_1_Ready  at 0 range 23 .. 23;
         Oscillator_32_Ready at 0 range 22 .. 22;
         Reserved_B          at 0 range 0 .. 21;
      end record;

   for Oscillator_Status_Register'Size use 32;

   pragma Suppress_Initialization (Oscillator_Status_Register);

   -----------------------------
   -- Power Manager Interface --
   -----------------------------

   type Power_Manager_Interface is
      record
         Main_Clock_Control    : Main_Clock_Control_Register;
         Clock_Select          : Clock_Select_Register;
         CPU_Mask              : Scaler_32;
         HSB_Mask              : Scaler_32;
         PBA_Mask              : Scaler_32;
         PBB_Mask              : Scaler_32;
         Reserved_A            : Reserved_32;
         Reserved_B            : Reserved_32;
         PPL_0_Control         : PPL_Control_Register;
         PPL_1_Control         : PPL_Control_Register;
         Oscillator_0_Control  : Oscillator_Control_Register;
         Oscillator_1_Control  : Oscillator_Control_Register;
         Unused_C              : Scaler_32;
         Reserved_C            : Reserved_32;
         Reserved_D            : Reserved_32;
         Reserved_E            : Reserved_32;
         Interrupt_Enable      : Scaler_32;
         Interrupt_Disable     : Scaler_32;
         Interrupt_Mask        : Scaler_32;
         Interrupt_Status      : Scaler_32;
         Interrupt_Clear       : Scaler_32;
         Status                : Oscillator_Status_Register;
         pragma Atomic (Main_Clock_Control);
         pragma Atomic (Clock_Select);
         pragma Atomic (CPU_Mask);
         pragma Atomic (HSB_Mask);
         pragma Atomic (PBA_Mask);
         pragma Atomic (PBB_Mask);
         pragma Atomic (PPL_0_Control);
         pragma Atomic (PPL_1_Control);
         pragma Atomic (Oscillator_0_Control);
         pragma Atomic (Oscillator_1_Control);
         pragma Atomic (Interrupt_Enable);
         pragma Atomic (Interrupt_Disable);
         pragma Atomic (Interrupt_Mask);
         pragma Atomic (Interrupt_Status);
         pragma Atomic (Interrupt_Clear);
         pragma Atomic (Status);
      end record;

   pragma Suppress_Initialization (Power_Manager_Interface);

   -------------------
   -- Power Manager --
   -------------------

   Power_Manager : aliased Power_Manager_Interface;
   for Power_Manager'Address use Power_Manager_Address;

   ----------------------------
   -- Flash Control Register --
   ----------------------------

   type Flash_Control_Register is
      record
         Ready_Interrupt         : Boolean;
         Reserved_A              : Reserved_1;
         Lock_Error_Interrupt    : Boolean;
         Program_Error_Interrupt : Boolean;
         Reserved_B              : Reserved_2;
         Wait_State              : Boolean;
         Reserved_C              : Reserved_1;
         Sense_Amplifier         : Boolean;
         Reserved_D              : Reserved_23;
      end record;

   for Flash_Control_Register use
      record
         Ready_Interrupt         at 0 range 31 .. 31;
         Reserved_A              at 0 range 30 .. 30;
         Lock_Error_Interrupt    at 0 range 29 .. 29;
         Program_Error_Interrupt at 0 range 28 .. 28;
         Reserved_B              at 0 range 26 .. 27;
         Wait_State              at 0 range 25 .. 25;
         Reserved_C              at 0 range 24 .. 24;
         Sense_Amplifier         at 0 range 23 .. 23;
         Reserved_D              at 0 range  0 .. 22;
      end record;

   for Flash_Control_Register'Size use 32;

   ---------------------
   -- Flash interface --
   ---------------------

   type Flash_Interface is
      record
         Control : Flash_Control_Register;
         pragma Atomic (Control);
      end record;

   ------------
   -- Flash  --
   ------------

   Flash : Flash_Interface;
   for Flash'Address use Flash_Address;

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

   --------------
   -- Requests --
   --------------

   Requests : aliased Interrupt_Request_Array;
   for Requests'Address use Interrupt_Request_Address;

   ---------------------------------
   -- Interrupt Priority Register --
   ---------------------------------

   type Interrupt_Priority_Register is
      record
         Autovector : Scaler_14;
         Reserved   : Reserved_16;
         Level      : Scaler_2;
      end record;

   for Interrupt_Priority_Register use
      record
         Autovector at 0 range 18 .. 31;
         Reserved   at 0 range 2 .. 17;
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

   ----------------
   -- Priorities --
   ----------------

   Priorities : aliased Interrupt_Priority_Array;
   for Priorities'Address use Interrupt_Priority_Address;

   ---------------------------------
   -- Interrupt Cause Register --
   ---------------------------------

   type Interrupt_Cause_Register is
      record
         Cause    : Scaler_6;
         Reserved : Reserved_26;
      end record;

   for Interrupt_Cause_Register use
      record
         Cause    at 0 range 26 .. 31;
         Reserved at 0 range 0 .. 25;
      end record;

   for Interrupt_Cause_Register'Size use 32;

   pragma Suppress_Initialization (Interrupt_Cause_Register);

   ---------------------------
   -- Interrupt Cause Array --
   ---------------------------

   type Interrupt_Cause_Array is
     array (0 .. 3) of Interrupt_Cause_Register;

   pragma Atomic_Components (Interrupt_Cause_Array);
   pragma Suppress_Initialization (Interrupt_Cause_Array);

   ------------
   -- Causes --
   ------------

   Causes : aliased Interrupt_Cause_Array;
   for Causes'Address use Interrupt_Cause_Address;

   ----------------------------
   -- USART Control Register --
   ----------------------------

   type USART_Control_Register is
      record
         Reserved_A   : Reserved_2;
         Reset_RX     : Boolean;
         Reset_TX     : Boolean;
         Enable_RX    : Boolean;
         Disable_RX   : Boolean;
         Enable_TX    : Boolean;
         Disable_TX   : Boolean;
         Reset_Status : Boolean;
         Reserved_B   : Reserved_23;
      end record;

   for USART_Control_Register use
      record
         Reserved_A   at 0 range 30 .. 31;
         Reset_RX     at 0 range 29 .. 29;
         Reset_TX     at 0 range 28 .. 28;
         Enable_RX    at 0 range 27 .. 27;
         Disable_RX   at 0 range 26 .. 26;
         Enable_TX    at 0 range 25 .. 25;
         Disable_TX   at 0 range 24 .. 24;
         Reset_Status at 0 range 23 .. 23;
         Reserved_B   at 0 range 0 .. 22;
      end record;

   for USART_Control_Register'Size use 32;

   pragma Suppress_Initialization (USART_Control_Register);

   -------------------------
   -- USART Mode Register --
   -------------------------

   type USART_Mode_Register is
      record
         Mode         : Scaler_4;
         Clock_Select : Scaler_2;
         Charlength   : Scaler_2;
         Synchronous  : Boolean;
         Parity       : Scaler_3;
         Stopbits     : Scaler_2;
         Channel_Mode : Scaler_2;
         Bit_Order    : Boolean;
         Charlength_9 : Boolean;
         Clock_Output : Boolean;
         Oversampling : Boolean;
         Reserved     : Reserved_12;
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
         Reserved     at 0 range 0 .. 11;
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
         Reserved : Reserved_30;
      end record;

   for USART_Status_Register use
      record
         RX_Ready at 0 range 31 .. 31;
         TX_Ready at 0 range 30 .. 30;
         Reserved at 0 range 0 .. 29;
      end record;

   for USART_Status_Register'Size use 32;

   pragma Suppress_Initialization (USART_Status_Register);

   ----------------------------
   -- USART Holding Register --
   ----------------------------

   type USART_Holding_Register is
      record
         Char : Character;
         Reserved : Reserved_24;
      end record;

   for USART_Holding_Register use
      record
         Char     at 0 range 24 .. 31;
         Reserved at 0 range 0 .. 23;
      end record;

   for USART_Holding_Register'Size use 32;

   pragma Suppress_Initialization (USART_Holding_Register);

   ---------------------------------------
   -- USART Baudrate Generator Register --
   ---------------------------------------

   type USART_Baudrate_Register is
      record
         Clock_Divider   : Scaler_16;
         Fractional_Part : Scaler_3;
         Reserved        : Reserved_13;
      end record;

   for USART_Baudrate_Register use
      record
         Clock_Divider   at 0 range 16 .. 31;
         Fractional_Part at 0 range 13 .. 15;
         Reserved        at 0 range 0 .. 12;
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

   -----------
   -- USART --
   -----------

   USART : aliased USART_Channel_Interface;
   for USART'Address use USART_Channel_1_Address;

   ------------------------------
   -- Channel Control Register --
   ------------------------------

   type TC_Channel_Control_Register is
      record
         Clock_Enable     : Boolean;
         Clock_Disable    : Boolean;
         Software_Trigger : Boolean;
         Reserved         : Reserved_29;
      end record;

   for TC_Channel_Control_Register use
      record
         Clock_Enable     at 0 range 31 .. 31;
         Clock_Disable    at 0 range 30 .. 30;
         Software_Trigger at 0 range 29 .. 29;
         Reserved         at 0 range 0 .. 28;
      end record;

   for TC_Channel_Control_Register'Size use 32;

   pragma Suppress_Initialization (TC_Channel_Control_Register);

   ---------------------------
   -- Channel Mode Register --
   ---------------------------

   type TC_Channel_Mode_Register is
      record
         Clock_Select           : Scaler_3;
         Clock_Invert           : Boolean;
         Burst_Select           : Scaler_2;
         Stop_RC_Compare        : Boolean;
         Disable_RC_Compare     : Boolean;
         Ext_Event_Edge         : Scaler_2;
         Ext_Event_Select       : Scaler_2;
         Ext_Event_Enable       : Boolean;
         Waveform_Select        : Scaler_2;
         Wave_Mode              : Boolean;
         RA_Compare_Effect_TIOA : Scaler_2;
         RC_Compare_Effect_TIOA : Scaler_2;
         Ext_Event_Effect_TIOA  : Scaler_2;
         SW_Trigger_Effect_TIOA : Scaler_2;
         RB_Compare_Effect_TIOB : Scaler_2;
         RC_Compare_Effect_TIOB : Scaler_2;
         Ext_Event_Effect_TIOB  : Scaler_2;
         SW_Trigger_Effect_TIOB : Scaler_2;
      end record;

   for TC_Channel_Mode_Register use
      record
         Clock_Select           at 0 range 29 .. 31;
         Clock_Invert           at 0 range 28 .. 28;
         Burst_Select           at 0 range 26 .. 27;
         Stop_RC_Compare        at 0 range 25 .. 25;
         Disable_RC_Compare     at 0 range 24 .. 24;
         Ext_Event_Edge         at 0 range 22 .. 23;
         Ext_Event_Select       at 0 range 20 .. 21;
         Ext_Event_Enable       at 0 range 19 .. 19;
         Waveform_Select        at 0 range 17 .. 18;
         Wave_Mode              at 0 range 16 .. 16;
         RA_Compare_Effect_TIOA at 0 range 14 .. 15;
         RC_Compare_Effect_TIOA at 0 range 12 .. 13;
         Ext_Event_Effect_TIOA  at 0 range 10 .. 11;
         SW_Trigger_Effect_TIOA at 0 range 8 .. 9;
         RB_Compare_Effect_TIOB at 0 range 6 .. 7;
         RC_Compare_Effect_TIOB at 0 range 4 .. 5;
         Ext_Event_Effect_TIOB  at 0 range 2 .. 3;
         SW_Trigger_Effect_TIOB at 0 range 0 .. 1;
      end record;

   for TC_Channel_Mode_Register'Size use 32;

   pragma Suppress_Initialization (TC_Channel_Mode_Register);

   -----------------------------
   -- Channel Status Register --
   -----------------------------

   type TC_Channel_Status_Register is
      record
         Counter_Overflow : Boolean;
         Load_Overrun     : Boolean;
         RA_Compare       : Boolean;
         RB_Compare       : Boolean;
         RC_Compare       : Boolean;
         RA_Loading       : Boolean;
         RB_Loading       : Boolean;
         Ext_Trigger      : Boolean;
         Reserved_A       : Reserved_8;
         Clock_Enabled    : Boolean;
         TIOA_Mirror      : Boolean;
         TIOB_Mirror      : Boolean;
         Reserved_B       : Reserved_13;
      end record;

   for TC_Channel_Status_Register use
      record
         Counter_Overflow at 0 range 31 .. 31;
         Load_Overrun     at 0 range 30 .. 30;
         RA_Compare       at 0 range 29 .. 29;
         RB_Compare       at 0 range 28 .. 28;
         RC_Compare       at 0 range 27 .. 27;
         RA_Loading       at 0 range 26 .. 26;
         RB_Loading       at 0 range 25 .. 25;
         Ext_Trigger      at 0 range 24 .. 24;
         Reserved_A       at 0 range 16 .. 23;
         Clock_Enabled    at 0 range 15 .. 15;
         TIOA_Mirror      at 0 range 14 .. 14;
         TIOB_Mirror      at 0 range 13 .. 13;
         Reserved_B       at 0 range 0 .. 12;
      end record;

   for TC_Channel_Status_Register'Size use 32;

   pragma Suppress_Initialization (TC_Channel_Status_Register);

   --------------------------------
   -- Interrupt Control Register --
   --------------------------------

   type TC_Interrupt_Control_Register is
      record
         Counter_Overflow : Boolean;
         Load_Overrun     : Boolean;
         RA_Compare       : Boolean;
         RB_Compare       : Boolean;
         RC_Compare       : Boolean;
         RA_Loading       : Boolean;
         RB_Loading       : Boolean;
         Ext_Trigger      : Boolean;
         Reserved         : Reserved_24;
      end record;

   for TC_Interrupt_Control_Register use
      record
         Counter_Overflow at 0 range 31 .. 31;
         Load_Overrun     at 0 range 30 .. 30;
         RA_Compare       at 0 range 29 .. 29;
         RB_Compare       at 0 range 28 .. 28;
         RC_Compare       at 0 range 27 .. 27;
         RA_Loading       at 0 range 26 .. 26;
         RB_Loading       at 0 range 25 .. 25;
         Ext_Trigger      at 0 range 24 .. 24;
         Reserved         at 0 range 0 .. 23;
      end record;

   for TC_Interrupt_Control_Register'Size use 32;

   pragma Suppress_Initialization (TC_Interrupt_Control_Register);

   ----------------------------
   -- Counter Value Register --
   ----------------------------

   type TC_Counter_Value_Register is
      record
         Value    : Timer_Interval;
         Reserved : Reserved_16;
      end record;

   for TC_Counter_Value_Register use
      record
         Value    at 0 range 16 .. 31;
         Reserved at 0 range 0 .. 15;
      end record;

   for TC_Counter_Value_Register'Size use 32;

   pragma Suppress_Initialization (TC_Counter_Value_Register);

   --------------------------
   -- TC Channel Interface --
   --------------------------

   type TC_Channel_Interface is
      record
         Control           : TC_Channel_Control_Register;
         Mode              : TC_Channel_Mode_Register;
         Reserved_A        : Reserved_32;
         Reserved_B        : Reserved_32;
         Counter           : TC_Counter_Value_Register;
         RA                : TC_Counter_Value_Register;
         RB                : TC_Counter_Value_Register;
         RC                : TC_Counter_Value_Register;
         Status            : TC_Channel_Status_Register;
         Interrupt_Enable  : TC_Interrupt_Control_Register;
         Interrupt_Disable : TC_Interrupt_Control_Register;
         Interrupt_Mask    : TC_Interrupt_Control_Register;
         pragma Atomic (Control);
         pragma Atomic (Mode);
         pragma Atomic (Counter);
         pragma Atomic (RA);
         pragma Atomic (RB);
         pragma Atomic (RC);
         pragma Atomic (Status);
         pragma Atomic (Interrupt_Enable);
         pragma Atomic (Interrupt_Disable);
         pragma Atomic (Interrupt_Mask);
      end record;

   pragma Suppress_Initialization (TC_Channel_Interface);

   ---------------------
   -- Clock and Alarm --
   ---------------------

   Clock : aliased TC_Channel_Interface;
   for Clock'Address use Timer_Counter_1_Address;

   Alarm : aliased TC_Channel_Interface;
   for Alarm'Address use Timer_Counter_2_Address;

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

   ------------------
   -- GPIO A and B --
   ------------------

   GPIO_Port_A : aliased GPIO_Port_Interface;
   for GPIO_Port_A'Address use GPIO_Port_A_Address;

   GPIO_Port_B : aliased GPIO_Port_Interface;
   for GPIO_Port_B'Address use GPIO_Port_B_Address;

end System.BB.Peripherals.Registers;
