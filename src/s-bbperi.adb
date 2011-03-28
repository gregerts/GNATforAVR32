------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                  S Y S T E M . B B . P E R I P H E R A L S               --
--                                                                          --
--                                  B o d y                                 --
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

pragma Restrictions (No_Elaboration_Code);

with Ada.Unchecked_Conversion;
with Interfaces;
with System.BB.Peripherals.Registers;

use System.BB.Peripherals.Registers;

package body System.BB.Peripherals is

   use type SBI.Interrupt_Level;
   use type SBI.Interrupt_ID;

   subtype Interrupt_Group is Natural range 0 .. (SBP.Interrupt_Groups - 1);
   subtype Interrupt_Line is Natural range 0 .. 15;

   --------------------------------
   -- Interrupt ID look-up table --
   --------------------------------

   type Interrupt_ID_Table is
     array (Interrupt_Group, Interrupt_Line) of SBI.Interrupt_ID;

   pragma Suppress_Initialization (Interrupt_ID_Table);
   pragma Pack (Interrupt_ID_Table);

   To_Interrupt_ID : constant Interrupt_ID_Table :=
     (0 => (COMPARE, others => 0),
      1 => (EIM_0, EIM_1, EIM_2, EIM_3, EIM_4,
            RTC, PM, FREQM, others => 0),
      2 => (GPIO_0, GPIO_1, GPIO_2, GPIO_3, GPIO_4, GPIO_5, GPIO_6, GPIO_7,
            GPIO_8, GPIO_9, GPIO_10, GPIO_11, GPIO_12, GPIO_13,
            others => 0),
      3 => (PDCA_0, PDCA_1, PDCA_2, PDCA_3, PDCA_4, PDCA_5, PDCA_6, PDCA_7,
            PDCA_8, PDCA_9, PDCA_10, PDCA_11, PDCA_12, PDCA_13, PDCA_14,
            others => 0),
      4 => (FLASHC, others => 0),
      5 => (USART_0, others => 0),
      6 => (USART_1, others => 0),
      7 => (USART_2, others => 0),
      8 => (USART_3, others => 0),
      9 => (SPI_0, others => 0),
      10 => (SPI_1, others => 0),
      11 => (TWI, others => 0),
      12 => (PWM, others => 0),
      13 => (SSC, others => 0),
      14 => (TC_0, TC_1, TC_2, others => 0),
      15 => (ADC, others => 0),
      16 => (MACB, others => 0),
      17 => (USB, others => 0),
      18 => (SDRAMC, others => 0));

   pragma Export (ASM, To_Interrupt_ID, "to_interrupt_id");

   -------------------------------------------
   -- Mapping of interrupt groups to levels --
   -------------------------------------------

   Group_To_Level : constant
     array (Interrupt_Group) of SBI.Interrupt_Level :=
     (0 | 14 => 3, others => 0);

   ------------------------------------------------
   -- Constants used for configurating registers --
   ------------------------------------------------

   Select_Osc_0     : constant := 1;
   Select_PPL_0     : constant := 2;
   Osc_Mode_Crystal : constant := 1;
   Parity_None      : constant := 4;
   Charlength_8     : constant := 3;
   Stopbits_1       : constant := 0;

   ---------------
   -- Registers --
   ---------------

   Power_Manager : aliased Power_Manager_Interface;
   for Power_Manager'Address use Power_Manager_Address;

   Flash : Flash_Interface;
   for Flash'Address use Flash_Address;

   Requests : aliased Interrupt_Request_Array;
   for Requests'Address use Interrupt_Request_Address;

   Priorities : aliased Interrupt_Priority_Array;
   for Priorities'Address use Interrupt_Priority_Address;

   USART : aliased USART_Channel_Interface;
   for USART'Address use USART_Channel_1_Address;

   GPIO_Port_A : aliased GPIO_Port_Interface;
   for GPIO_Port_A'Address use GPIO_Port_A_Address;

   GPIO_Port_B : aliased GPIO_Port_Interface;
   for GPIO_Port_B'Address use GPIO_Port_B_Address;

   -----------------------
   -- Local definitions --
   -----------------------

   type Autovector_Array is array (SBI.Interrupt_Level) of Scaler_32;
   pragma Suppress_Initialization (Autovector_Array);

   type GPIO_Peripheral is (Peripheral_A,
                            Peripheral_B,
                            Peripheral_C);

   subtype GPIO_Pin is Natural range 0 .. 31;

   --------------------
   -- Local routines --
   --------------------

   procedure Initialize_Power_Manager;
   --  Procedure initializing the Power Manager.

   procedure Initialize_Interrupts;
   --  Procedure initializing the Interrupt Controller.

   procedure GPIO_Configure_Peripheral
     (Port        : access GPIO_Port_Interface;
      From        : GPIO_Pin;
      To          : GPIO_Pin;
      Peripheral  : GPIO_Peripheral);
   pragma Inline (GPIO_Configure_Peripheral);
   --  Multiplex the given pin to the given peripheral.

   function To_Mask (From, To : GPIO_Pin) return GPIO_Mask;
   pragma Inline (To_Mask);
   --  Makes a mask out of a pin.

   ----------------------
   -- Initialize_Board --
   ----------------------

   procedure Initialize_Board is
   begin
      Initialize_Power_Manager;
      --  Initialize the power manager.

      Initialize_Interrupts;
      --  Initialize the interrupt controller.

   end Initialize_Board;

   ------------------------------
   -- Initialize_Power_Manager --
   ------------------------------

   procedure Initialize_Power_Manager is

      Main : Main_Clock_Control_Register := Power_Manager.Main;

      pragma Warnings (Off, SBP.Flash_Wait_State);
      pragma Warnings (Off, SBP.Clock_Multiplication);

   begin

      --  Enable Oscillator 0

      Power_Manager.Osc_0 :=
        (Mode => Osc_Mode_Crystal, Startup => 7, others => <>);

      Main.Enable_Osc_0 := True;
      Power_Manager.Main := Main;

      while not Power_Manager.Status.Osc_0_Ready loop
         null;
      end loop;

      --  Enable PPL 0 in necessary

      if SBP.Clock_Multiplication > 1 then

         --  Enable PPL 0

         Power_Manager.PPL_0 :=
           (Enable  => True,
            Osc     => 0,
            Options => 2,
            Div     => 0,
            Mult    => SBP.Clock_Multiplication - 1,
            Count   => 16,
            others  => <>);

         while not Power_Manager.Status.Lock_PPL_0 loop
            null;
         end loop;

         --  Enable Flash wait state

         if SBP.Flash_Wait_State > 0 then
            Flash.Control := (Wait_State => True, others => <>);
         end if;

         --  Switch to PPL 0

         Main.Clock_Select  := Select_PPL_0;
         Power_Manager.Main := Main;

      else

         --  Switch to Oscillator 0

         Main.Clock_Select := Select_Osc_0;
         Power_Manager.Main := Main;

      end if;

   end Initialize_Power_Manager;

   ---------------------------
   -- Initialize_Interrupts --
   ---------------------------

   procedure Initialize_Interrupts is
      Pri : Interrupt_Priority_Register;
      Autovectors : Autovector_Array;
      pragma Import (Asm, Autovectors, "autovectors");
   begin

      --  Initialize all groups to their predefined level.

      for I in Interrupt_Group loop
         Pri.Level      := Scaler_2 (Group_To_Level (I));
         Pri.Autovector := Scaler_14 (Autovectors (Group_To_Level (I)));
         Priorities (I) := Pri;
      end loop;

   end Initialize_Interrupts;

   --------------
   -- To_Level --
   --------------

   function To_Level
     (Interrupt : SBI.Interrupt_ID) return SBI.Interrupt_Level
   is
   begin

      pragma Assert (Interrupt /= SBI.No_Interrupt);

      for I in Interrupt_Group loop
         if To_Interrupt_ID (I, 0) > Interrupt then
            return Group_To_Level (I - 1);
         end if;
      end loop;

      return SBI.Interrupt_Level'First;

   end To_Level;

   ------------------------
   -- Initialize_Console --
   ------------------------

   procedure Initialize_Console is

      Baud : constant := SBP.USART_Baudrate;
      Freq : constant := Main_Clock_Frequency;

      pragma Warnings (Off, Baud);
      pragma Warnings (Off, Freq);
      pragma Warnings (Off, USART_Channel_0_Address);

      Div  : Positive;
      Over : Boolean;
      Sync : Boolean;

   begin

      --  Initialize GPIO pins for USART channel.

      if USART'Address = USART_Channel_0_Address then
         GPIO_Configure_Peripheral (GPIO_Port_A'Access, 0, 4, Peripheral_A);
      else
         GPIO_Configure_Peripheral (GPIO_Port_A'Access, 5, 9, Peripheral_A);
      end if;

      --  Calculate and set baudrate.

      if Baud < (Freq / 16) then
         Over := False;
         Sync := False;
         Div  := (Freq + 8 * Baud) / (16 * Baud);
      elsif Baud < (Freq / 8) then
         Over := True;
         Sync := False;
         Div  := (Freq + 4 * Baud) / (8 * Baud);
      else
         Over := False;
         Sync := True;
         Div  := Freq / Baud;
      end if;

      USART.Baudrate := (Clock_Divider => Scaler_16 (Div), others => <>);

      --  Set USART transmission mode to normal and 8N1

      USART.Mode :=
        (Charlength   => Charlength_8,
         Parity       => Parity_None,
         Stopbits     => Stopbits_1,
         Oversampling => Over,
         Synchronous  => Sync,
         others       => <>);

      --  Enable TX

      USART.Control := (Enable_TX => True, others => <>);

   end Initialize_Console;

   ------------------
   -- Console_Send --
   ------------------

   procedure Console_Send (Char : Character) is
   begin
      while not USART.Status.TX_Ready loop
         null;
      end loop;
      USART.TX.Char := Char;
   end Console_Send;

   -------------------------------
   -- GPIO_Configure_Peripheral --
   -------------------------------

   procedure GPIO_Configure_Peripheral
     (Port       : access GPIO_Port_Interface;
      From       : GPIO_Pin;
      To         : GPIO_Pin;
      Peripheral : GPIO_Peripheral)
   is
      Mask : constant GPIO_Mask := To_Mask (From, To);
   begin
      Port.GPIO_Enable.Clear := Mask;

      case Peripheral is
         when Peripheral_A =>
            Port.Peripheral_Mux_0.Clear := Mask;
            Port.Peripheral_Mux_1.Clear := Mask;

         when Peripheral_B =>
            Port.Peripheral_Mux_0.Set   := Mask;
            Port.Peripheral_Mux_1.Clear := Mask;

         when Peripheral_C =>
            Port.Peripheral_Mux_0.Clear := Mask;
            Port.Peripheral_Mux_1.Set   := Mask;
      end case;
   end GPIO_Configure_Peripheral;

   -------------
   -- To_Mask --
   -------------

   function To_Mask (From, To : GPIO_Pin) return GPIO_Mask
   is
      use type Interfaces.Unsigned_32;

      Mask : Interfaces.Unsigned_32 := 1;
   begin
      pragma Assert (From <= To);

      Mask := Interfaces.Shift_Left (Mask, Natural (To - From + 1)) - 1;
      Mask := Interfaces.Shift_Left (Mask, Natural (From));

      return GPIO_Mask (Mask);
   end To_Mask;

end System.BB.Peripherals;
