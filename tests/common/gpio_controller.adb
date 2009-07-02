with System;
with Interfaces;

package body GPIO_Controller is

   Ports : array (Port_Number) of GPIO_Port_Interface;
   for Ports'Alignment use 16#100#;
   for Ports'Address use System'To_Address (16#FFFF1000#);
   pragma Volatile_Components (Ports);

   --------------------
   -- Configure_GPIO --
   --------------------

   procedure Configure_GPIO
     (Port   : in Port_Number;
      Pin    : in Pin_Number;
      Config : in Pin_Config := Default_Config)
   is
   begin
      Configure_GPIO (Port, Pin_To_Mask (Pin), Config);
   end Configure_GPIO;

   --------------------
   -- Configure_GPIO --
   --------------------

   procedure Configure_GPIO
     (Port   : in Port_Number;
      Mask   : in Pin_Mask;
      Config : in Pin_Config := Default_Config)
   is
   begin
      --------------------------------
      -- Configure pin multiplexing --
      --------------------------------

      Ports (Port).GPIO_Enable.Set := Mask;

      ------------------------
      -- Configure pin mode --
      ------------------------

      if Config.Open_Drain then
         Ports (Port).Open_Drain_Enable.Set := Mask;
      else
         Ports (Port).Open_Drain_Enable.Clear := Mask;
      end if;

      if Config.Pull_Up then
         Ports (Port).Pull_Up_Enable.Set := Mask;
      else
         Ports (Port).Pull_Up_Enable.Clear := Mask;
      end if;

      if Config.Deglitch then
         Ports (Port).Glitch_Filter_Enable.Set := Mask;
      else
         Ports (Port).Glitch_Filter_Enable.Clear := Mask;
      end if;

   end Configure_GPIO;

   --------------------------
   -- Configure_Peripheral --
   --------------------------

   procedure Configure_Peripheral
     (Port       : in Port_Number;
      Pin        : in Pin_Number;
      Peripheral : in Pin_Peripheral)
   is
   begin
      Configure_Peripheral (Port, Pin_To_Mask (Pin), Peripheral);
   end Configure_Peripheral;

   --------------------------
   -- Configure_Peripheral --
   --------------------------

   procedure Configure_Peripheral
     (Port       : in Port_Number;
      Mask       : in Pin_Mask;
      Peripheral : in Pin_Peripheral)
   is
   begin
      --------------------------------
      -- Configure pin multiplexing --
      --------------------------------

      Ports (Port).GPIO_Enable.Clear := Mask;

      case Peripheral is
         when Peripheral_A =>
            Ports (Port).Peripheral_Mux_0.Clear := Mask;
            Ports (Port).Peripheral_Mux_1.Clear := Mask;

         when Peripheral_B =>
            Ports (Port).Peripheral_Mux_0.Set   := Mask;
            Ports (Port).Peripheral_Mux_1.Clear := Mask;

         when Peripheral_C =>
            Ports (Port).Peripheral_Mux_0.Clear := Mask;
            Ports (Port).Peripheral_Mux_1.Set   := Mask;
      end case;

   end Configure_Peripheral;

   ----------------------
   -- Enable_Interrupt --
   ----------------------

   procedure Enable_Interrupt
     (Port : in Port_Number;
      Pin  : in Pin_Number;
      Edge : in Pin_Edge)
   is
   begin
      Enable_Interrupt (Port, Pin_To_Mask (Pin), Edge);
   end Enable_Interrupt;

   ----------------------
   -- Enable_Interrupt --
   ----------------------

   procedure Enable_Interrupt
     (Port : in Port_Number;
      Mask : in Pin_Mask;
      Edge : in Pin_Edge)
   is
   begin
      -----------------------------
      -- Configure pin interrupt --
      -----------------------------

      case Edge is
         when Both =>
            Ports (Port).Interrupt_Mode_0.Clear := Mask;
            Ports (Port).Interrupt_Mode_1.Clear := Mask;

         when Rising =>
            Ports (Port).Interrupt_Mode_0.Set   := Mask;
            Ports (Port).Interrupt_Mode_1.Clear := Mask;

         when Falling =>
            Ports (Port).Interrupt_Mode_0.Clear := Mask;
            Ports (Port).Interrupt_Mode_1.Set   := Mask;
      end case;

      Ports (Port).Interrupt_Enable.Set := Mask;

   end Enable_Interrupt;


   -----------------------
   -- Disable_Interrupt --
   -----------------------

   procedure Disable_Interrupt
     (Port : in Port_Number;
      Pin  : in Pin_Number)
   is
   begin
      Disable_Interrupt (Port, Pin_To_Mask (Pin));
   end Disable_Interrupt;

   -----------------------
   -- Disable_Interrupt --
   -----------------------

   procedure Disable_Interrupt
     (Port : in Port_Number;
      Mask : in Pin_Mask)
   is
   begin
      Ports (Port).Interrupt_Enable.Clear := Mask;
   end Disable_Interrupt;

   -------------------
   -- Get_Pin_Value --
   -------------------

   function Get_Pin_Value
     (Port : Port_Number;
      Pin  : Pin_Number)
     return Boolean
   is
   begin
      return Ports (Port).Pin_Value.RW (31 - Pin);
   end Get_Pin_Value;

   --------------------------
   -- Get_Pin_Output_Value --
   --------------------------

   function Get_Pin_Output_Value
     (Port : Port_Number;
      Pin  : Pin_Number)
     return Boolean
   is
   begin
      return Ports (Port).Output_Value.RW (31 - Pin);
   end Get_Pin_Output_Value;

   -------------
   -- Set_Pin --
   -------------

   procedure Set_Pin
     (Port  : in Port_Number;
      Pin   : in Pin_Number)
   is
   begin
      Set_Pins (Port, Pin_To_Mask (Pin));
   end Set_Pin;

   --------------
   -- Set_Pins --
   --------------

   procedure Set_Pins
     (Port  : in Port_Number;
      Mask  : in Pin_Mask)
   is
   begin
      Ports (Port).Pin_Value.Set := Mask;
   end Set_Pins;

   ---------------
   -- Clear_Pin --
   ---------------

   procedure Clear_Pin
     (Port : in Port_Number;
      Pin  : in Pin_Number)
   is
   begin
      Clear_Pins (Port, Pin_To_Mask (Pin));
   end Clear_Pin;

   ----------------
   -- Clear_Pins --
   ----------------

   procedure Clear_Pins
     (Port : in Port_Number;
      Mask : in Pin_Mask)
   is
   begin
      Ports (Port).Pin_Value.Clear := Mask;
   end Clear_Pins;

   ----------------
   -- Toggle_Pin --
   ----------------

   procedure Toggle_Pin
     (Port : in Port_Number;
      Pin  : in Pin_Number)
   is
   begin
      Toggle_Pins (Port, Pin_To_Mask (Pin));
   end Toggle_Pin;

   -----------------
   -- Toggle_Pins --
   -----------------

   procedure Toggle_Pins
     (Port : in Port_Number;
      Mask : in Pin_Mask)
   is
   begin
      Ports (Port).Pin_Value.Toggle := Mask;
   end Toggle_Pins;

   -----------------
   -- Pin_To_Mask --
   -----------------

   function Pin_To_Mask (Pin : Pin_Number) return Pin_Mask is
      Offset : constant Natural := Natural (Pin);
      Mask   : constant Interfaces.Unsigned_32 := 1;
   begin
      return Pin_Mask (Interfaces.Shift_Left (Mask, Offset));
   end Pin_To_Mask;

   -------------------
   -- Range_To_Mask --
   -------------------

   function Range_To_Mask (From, To : Pin_Number) return Pin_Mask
   is
      use type Interfaces.Unsigned_32;

      Mask : Interfaces.Unsigned_32 := 1;
   begin
      pragma Assert (From <= To);

      Mask := Interfaces.Shift_Left (Mask, Natural (To - From + 1)) - 1;
      Mask := Interfaces.Shift_Left (Mask, Natural (From));

      return Pin_Mask (Mask);
   end Range_To_Mask;

end GPIO_Controller;
