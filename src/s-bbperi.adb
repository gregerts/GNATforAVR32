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
with System.Machine_Code;
with System.BB.Peripherals.Registers;

use System.BB.Peripherals.Registers;

package body System.BB.Peripherals is

   package SMC renames System.Machine_Code;

   use type SBI.Interrupt_Level;
   use type SBI.Interrupt_ID;

   -------------------------------------------
   -- Mapping of interrupt groups to levels --
   -------------------------------------------

   Group_To_Level : constant array (Interrupt_Group) of SBI.Interrupt_Level
     := (Group_0_Level,
         Group_1_Level,
         Group_2_Level,
         Group_3_Level,
         Group_4_Level,
         Group_5_Level,
         Group_6_Level,
         Group_7_Level,
         Group_8_Level,
         Group_9_Level,
         Group_10_Level,
         Group_11_Level,
         Group_12_Level,
         Group_13_Level,
         Group_14_Level,
         Group_15_Level,
         Group_16_Level,
         Group_17_Level,
         Group_18_Level,
         Group_19_Level);

   ------------------------------------------------
   -- Constants used for configurating registers --
   ------------------------------------------------

   Select_Osc_0     : constant := 1;
   Select_PPL_0     : constant := 2;
   Osc_Mode_Crystal : constant := 1;
   Parity_None      : constant := 4;
   Charlength_8     : constant := 3;
   Stopbits_1       : constant := 0;
   Timer_Clock_2    : constant := 1;
   Timer_Clock_3    : constant := 2;
   Timer_Clock_4    : constant := 3;
   Timer_Clock_5    : constant := 4;
   Up_No_Trigger    : constant := 0;
   Up_RC_Trigger    : constant := 2;

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

   Causes : aliased Interrupt_Cause_Array;
   for Causes'Address use Interrupt_Cause_Address;

   USART : aliased USART_Channel_Interface;
   for USART'Address use USART_Channel_1_Address;

   Clock : aliased TC_Channel_Interface;
   for Clock'Address use Timer_Counter_1_Address;

   Alarm : aliased TC_Channel_Interface;
   for Alarm'Address use Timer_Counter_2_Address;

   GPIO_Port_A : aliased GPIO_Port_Interface;
   for GPIO_Port_A'Address use GPIO_Port_A_Address;

   GPIO_Port_B : aliased GPIO_Port_Interface;
   for GPIO_Port_B'Address use GPIO_Port_B_Address;

   TMU : aliased TMU_Interface;
   for TMU'Address use TMU_Address;

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

   procedure Initialize_Timers;
   --  Procedure initializing the Timer / Counter.

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

      Initialize_Timers;
      --  Initialize the timer / counter module.
   end Initialize_Board;

   ------------------------------
   -- Initialize_Power_Manager --
   ------------------------------

   procedure Initialize_Power_Manager is

      Main : Main_Clock_Control_Register := Power_Manager.Main;
      Peripheral : Scaler_3;

      pragma Warnings (Off, SBP.Flash_Wait_State);
      pragma Warnings (Off, SBP.Clock_Multiplication);
      pragma Warnings (Off, SBP.Peripheral_Division);

   begin

      --  Enable Oscillator 0

      Power_Manager.Osc_0 :=
        (Mode => Osc_Mode_Crystal, Startup => 4, others => <>);

      Main.Enable_Osc_0 := True;
      Power_Manager.Main := Main;

      while not Power_Manager.Status.Osc_0_Ready loop
         null;
      end loop;

      --  Switch to Oscillator 0

      Main.Clock_Select := Select_Osc_0;
      Power_Manager.Main := Main;

      --  Setup PBA and PBB clock scaling

      if SBP.Peripheral_Division > 1 then

         case SBP.Peripheral_Division is
            when 2 =>
               Peripheral := 0;
            when 4 =>
               Peripheral := 1;
            when 8 =>
               Peripheral := 2;
            when 16 =>
               Peripheral := 3;
            when 32 =>
               Peripheral := 4;
            when 64 =>
               Peripheral := 5;
            when 128 =>
               Peripheral := 6;
            when 256 =>
               Peripheral := 7;
            when others =>
               Peripheral := 7;
         end case;

         Power_Manager.Clock_Select :=
           (PBA_Div    => True,
            PBA_Select => Peripheral,
            PBB_Div    => True,
            PBB_Select => Peripheral,
            others     => <>);

      end if;

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

      end if;

   end Initialize_Power_Manager;

   ---------------------------
   -- Initialize_Interrupts --
   ---------------------------

   procedure Initialize_Interrupts is

      Level       : SBI.Interrupt_Level;
      Priority    : Interrupt_Priority_Register;
      Autovectors : Autovector_Array;

      pragma Import (Asm, Autovectors, "autovectors");

   begin
      --  Initialize all groups to their predefined level.
      for I in Interrupt_Group loop
         Level               := Group_To_Level (I);
         Priority.Level      := Scaler_2  (Level) - 1;
         Priority.Autovector := Scaler_14 (Autovectors (Level));
         Priorities (I)      := Priority;
      end loop;

   end Initialize_Interrupts;

   ----------------------
   -- Get_Interrupt_ID --
   ----------------------

   function Get_Interrupt_ID
     (Level : SBI.Interrupt_Level)
      return SBI.Interrupt_ID
   is
      Interrupt : SBI.Interrupt_ID;
      Group     : Interrupt_Group;
      Line      : Natural;
      Aux       : Scaler_32;
   begin
      --  Assert that it is a external interrupt level.
      pragma Assert (Level > 0);

      --  Get Group from Interrupt Cause Register.
      Group := Interrupt_Group (Causes (4 - Level).Cause);

      --  Get Line from Interrupt Request Register by subtracting the
      --  number of leading zeros in request register from 32.
      Aux := Requests (Group);

      SMC.Asm ("clz %0, %1",
               Inputs => Scaler_32'Asm_Input ("r", Aux),
               Outputs => Scaler_32'Asm_Output ("=r", Aux));

      Line := Natural (32 - Aux);

      --  Determine Interrupt_ID from Group and Line.
      if Line > 0 then
         case Group is
            when 0 =>
               Interrupt := COMPARE;
            when 1 =>
               Interrupt := EIM_0 + SBI.Interrupt_ID (Line) - 1;
            when 2 =>
               Interrupt := GPIO_0 + SBI.Interrupt_ID (Line) - 1;
            when 3 =>
               Interrupt := PDCA_0 + SBI.Interrupt_ID (Line) - 1;
            when 4 .. 13 =>
               Interrupt := FLASHC + SBI.Interrupt_ID (Group - 4);
            when 14 =>
               Interrupt := TC_0 + SBI.Interrupt_ID (Line) - 1;
            when 15 .. 18 =>
               Interrupt := ADC + SBI.Interrupt_ID (Group - 15);
            when 19 =>
               Interrupt := TMUC;
         end case;
      else
         Interrupt := SBI.No_Interrupt;
      end if;

      return Interrupt;
   end Get_Interrupt_ID;

   --------------
   -- To_Level --
   --------------

   function To_Level
     (Interrupt : SBI.Interrupt_ID) return SBI.Interrupt_Level
   is
      Group : Interrupt_Group;
   begin
      --  This is a UC3A specific mapping of interrupts to groups.
      case (Interrupt) is
         when ADC .. SDRAMC =>
            Group := 15 + Interrupt_Group (Interrupt - ADC);
         when TC_0 .. TC_2 =>
            Group := 14;
         when FLASHC .. SSC =>
            Group := 4 + Interrupt_Group (Interrupt - FLASHC);
         when PDCA_0 .. PDCA_14 =>
            Group := 3;
         when GPIO_0 .. GPIO_13 =>
            Group := 2;
         when EIM_0 .. FREQM =>
            Group := 1;
         when COMPARE =>
            Group := 0;
         when others =>
            Group := 0;
      end case;

      return Group_To_Level (Group);
   end To_Level;

   -----------------------
   -- Initialize_Timers --
   -----------------------

   procedure Initialize_Timers is
      C : Scaler_3;
   begin

      case Parameters.Timer_Division is
         when 4 =>
            C := Timer_Clock_2;
         when 8 =>
            C := Timer_Clock_3;
         when 16 =>
            C := Timer_Clock_4;
         when 32 =>
            C := Timer_Clock_5;
         when others =>
            C := Timer_Clock_2;
      end case;

      --  Initialize clock

      Clock.Mode :=
        (Clock_Select    => C,
         Wave_Mode       => True,
         Waveform_Select => Up_No_Trigger,
         others          => <>);

      Clock.Interrupt_Enable := (Counter_Overflow => True, others => <>);

      Clock.Control :=
        (Clock_Enable       => True,
         Software_Trigger   => True,
         others             => <>);

      --  Initialize alarm

      Alarm.Mode :=
        (Clock_Select       => C,
         Wave_Mode          => True,
         Waveform_Select    => Up_RC_Trigger,
         Stop_RC_Compare    => True,
         Disable_RC_Compare => True,
         others             => <>);

      Alarm.Interrupt_Enable := (RC_Compare => True, others => <>);

   end Initialize_Timers;

   ---------------
   -- Set_Alarm --
   ---------------

   procedure Set_Alarm (Ticks : Timer_Interval) is
   begin

      Alarm.RC.Value := Ticks;

      Alarm.Control :=
        (Clock_Enable     => True,
         Software_Trigger => True,
         others           => <>);

   end Set_Alarm;

   ------------------
   -- Cancel_Alarm --
   ------------------

   procedure Cancel_Alarm is
   begin
      Alarm.Control := (Clock_Disable => True, others => <>);
      Clear_Alarm_Interrupt;
   end Cancel_Alarm;

   -------------------
   -- Pending_Clock --
   -------------------

   function Pending_Clock return Boolean is
   begin
      return (Requests (14) and 2) > 0;
   end Pending_Clock;

   ----------------
   -- Read_Clock --
   ----------------

   function Read_Clock return Timer_Interval is
   begin
      return Clock.Counter.Value;
   end Read_Clock;

   --------------------------
   -- Clear_Clock_Interupt --
   --------------------------

   procedure Clear_Clock_Interrupt is
      Status : constant TC_Channel_Status_Register := Clock.Status;
      pragma Unreferenced (Status);
   begin
      --  Interrupt cleared by reading status register.
      null;
   end Clear_Clock_Interrupt;

   --------------------------
   -- Clear_Alarm_Interupt --
   --------------------------

   procedure Clear_Alarm_Interrupt is
      Status : constant TC_Channel_Status_Register := Alarm.Status;
      pragma Unreferenced (Status);
   begin
      --  Interrupt cleared by reading status register.
      null;
   end Clear_Alarm_Interrupt;

   -----------------
   -- Set_Compare --
   -----------------

   procedure Set_Compare (Compare : TMU_Interval) is
   begin
      TMU.Compare := Compare;
   end Set_Compare;

   ---------------
   -- Set_Count --
   ---------------

   procedure Set_Count (Count : TMU_Interval) is
   begin
      TMU.Count := Count;
   end Set_Count;

   ------------------
   -- Swap_Context --
   ------------------

   procedure Swap_Context
     (Compare_A : TMU_Interval;
      Count_A   : TMU_Interval;
      Count_B   : out TMU_Interval)
   is
   begin
      TMU.Swap_Compare := Compare_A;
      TMU.Swap_Count   := Count_A;
      Count_B          := TMU.Swap_Count;
   end Swap_Context;

   ---------------
   -- Get_Count --
   ---------------

   function Get_Count return TMU_Interval is
   begin
      return TMU.Count;
   end Get_Count;

   ------------------------
   -- Initialize_Console --
   ------------------------

   procedure Initialize_Console is

      Baud : constant := SBP.USART_Baudrate;
      Freq : constant := Peripheral_Frequency;

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
