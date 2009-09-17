with System;

package body GPIO_Controller is

   --------------------
   -- Configure_GPIO --
   --------------------

   procedure Configure_GPIO
     (Port       : Port_Id;
      Mask       : Pin_Mask;
      Output     : Boolean := False;
      Open_Drain : Boolean := False;
      Pull_Up    : Boolean := False)
   is
   begin

      Port.GPIO_Enable.Set := Mask;

      if Output then

         Port.Output_Driver.Set := Mask;

         if Open_Drain then
            Port.Open_Drain_Enable.Set := Mask;
         else
            Port.Open_Drain_Enable.Clear := Mask;
         end if;

         if Pull_Up then
            Port.Pull_Up_Enable.Set := Mask;
         else
            Port.Pull_Up_Enable.Clear := Mask;
         end if;

      else
         Port.Output_Driver.Clear := Mask;
      end if;

   end Configure_GPIO;

   --------------------------
   -- Configure_Peripheral --
   --------------------------

   procedure Configure_Peripheral
     (Port       : Port_Id;
      Mask       : Pin_Mask;
      Peripheral : Pin_Peripheral)
   is
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

   end Configure_Peripheral;

   ----------------------
   -- Enable_Interrupt --
   ----------------------

   procedure Enable_Interrupt
     (Port     : Port_Id;
      Mask     : Pin_Mask;
      Edge     : Pin_Edge := Both;
      Deglitch : Boolean  := False)
   is
   begin

      pragma Assert ((Port.GPIO_Enable.RW and Mask) = Mask);
      pragma Assert ((Port.Output_Driver.RW and Mask) = 0);

      case Edge is
         when Both =>
            Port.Interrupt_Mode_0.Clear := Mask;
            Port.Interrupt_Mode_1.Clear := Mask;
         when Rising =>
            Port.Interrupt_Mode_0.Set   := Mask;
            Port.Interrupt_Mode_1.Clear := Mask;
         when Falling =>
            Port.Interrupt_Mode_0.Clear := Mask;
            Port.Interrupt_Mode_1.Set   := Mask;
      end case;

      if Deglitch then
         Port.Glitch_Filter_Enable.Set := Mask;
      else
         Port.Glitch_Filter_Enable.Clear := Mask;
      end if;

      Port.Interrupt_Enable.Set := Mask;

   end Enable_Interrupt;

   -----------------------
   -- Disable_Interrupt --
   -----------------------

   procedure Disable_Interrupt
     (Port : Port_Id;
      Mask : Pin_Mask)
   is
   begin
      Port.Interrupt_Enable.Clear := Mask;
   end Disable_Interrupt;

   -------------------
   -- Get_Pin_Value --
   -------------------

   function Get_Pin_Value
     (Port : Port_Id;
      Pin  : Pin_Number)
     return Boolean
   is
   begin
      return (Port.Pin_Value.RW and Pin_To_Mask (Pin)) > 0;
   end Get_Pin_Value;

   --------------------------
   -- Get_Pin_Output_Value --
   --------------------------

   function Get_Pin_Output_Value
     (Port : Port_Id;
      Pin  : Pin_Number)
     return Boolean
   is
   begin
      return (Port.Output_Value.RW and Pin_To_Mask (Pin)) > 0;
   end Get_Pin_Output_Value;

   -------------
   -- Set_Pin --
   -------------

   procedure Set_Pin
     (Port  : Port_Id;
      Pin   : Pin_Number)
   is
   begin
      Set_Pins (Port, Pin_To_Mask (Pin));
   end Set_Pin;

   --------------
   -- Set_Pins --
   --------------

   procedure Set_Pins
     (Port  : Port_Id;
      Mask  : Pin_Mask)
   is
   begin
      Port.Output_Value.Set := Mask;
   end Set_Pins;

   ---------------
   -- Clear_Pin --
   ---------------

   procedure Clear_Pin
     (Port : Port_Id;
      Pin  : Pin_Number)
   is
   begin
      Clear_Pins (Port, Pin_To_Mask (Pin));
   end Clear_Pin;

   ----------------
   -- Clear_Pins --
   ----------------

   procedure Clear_Pins
     (Port : Port_Id;
      Mask : Pin_Mask)
   is
   begin
      Port.Output_Value.Clear := Mask;
   end Clear_Pins;

   ----------------
   -- Toggle_Pin --
   ----------------

   procedure Toggle_Pin
     (Port : Port_Id;
      Pin  : Pin_Number)
   is
   begin
      Toggle_Pins (Port, Pin_To_Mask (Pin));
   end Toggle_Pin;

   -----------------
   -- Toggle_Pins --
   -----------------

   procedure Toggle_Pins
     (Port : Port_Id;
      Mask : Pin_Mask)
   is
   begin
      Port.Output_Value.Toggle := Mask;
   end Toggle_Pins;

   -----------------
   -- Pin_To_Mask --
   -----------------

   function Pin_To_Mask (Pin : Pin_Number) return Pin_Mask is
   begin
      return Interfaces.Shift_Left (1, Pin);
   end Pin_To_Mask;

   -------------------
   -- Range_To_Mask --
   -------------------

   function Range_To_Mask (From, To : Pin_Number) return Pin_Mask
   is
      pragma Suppress (Range_Check);
      Diff : constant Pin_Number := To - From;
   begin
      pragma Assert (From <= To);
      return Shift_Left (Shift_Left (2, Diff) - 1, From);
   end Range_To_Mask;

end GPIO_Controller;
