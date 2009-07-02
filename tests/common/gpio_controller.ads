package GPIO_Controller is

   subtype Port_Number is Natural range 0 .. 4;

   Port_A : constant := 0;
   Port_B : constant := 1;
   Port_C : constant := 2;
   Port_X : constant := 3;

   subtype Pin_Number is Natural range 0 .. 31;

   type Pin_Mask is private;

   type Pin_Peripheral is (Peripheral_A,
                           Peripheral_B,
                           Peripheral_C);

   type Pin_Edge is (Both, Rising, Falling);

   type Pin_Config is
      record
         Open_Drain : Boolean  := False;
         Pull_Up    : Boolean  := False;
         Deglitch   : Boolean  := False;
         Interrupt  : Boolean  := False;
         Edge       : Pin_Edge := Both;
      end record;

   Default_Config : constant Pin_Config
     := (False, False, False, False, Both);

   procedure Configure_GPIO
     (Port   : in Port_Number;
      Pin    : in Pin_Number;
      Config : in Pin_Config := Default_Config);

   procedure Configure_GPIO
     (Port   : in Port_Number;
      Mask   : in Pin_Mask;
      Config : in Pin_Config := Default_Config);

   procedure Configure_Peripheral
     (Port       : in Port_Number;
      Pin        : in Pin_Number;
      Peripheral : in Pin_Peripheral);

   procedure Configure_Peripheral
     (Port       : in Port_Number;
      Mask       : in Pin_Mask;
      Peripheral : in Pin_Peripheral);

   procedure Enable_Interrupt
     (Port : in Port_Number;
      Pin  : in Pin_Number;
      Edge : in Pin_Edge);

   procedure Enable_Interrupt
     (Port : in Port_Number;
      Mask : in Pin_Mask;
      Edge : in Pin_Edge);

   procedure Disable_Interrupt
     (Port : in Port_Number;
      Pin  : in Pin_Number);

   procedure Disable_Interrupt
     (Port : in Port_Number;
      Mask : in Pin_Mask);

   function Get_Pin_Value
     (Port : Port_Number;
      Pin  : Pin_Number)
     return Boolean;

   function Get_Pin_Output_Value
     (Port : Port_Number;
      Pin  : Pin_Number)
     return Boolean;

   procedure Set_Pin
     (Port  : in Port_Number;
      Pin   : in Pin_Number);

   procedure Set_Pins
     (Port  : in Port_Number;
      Mask  : in Pin_Mask);

   procedure Clear_Pin
     (Port : in Port_Number;
      Pin  : in Pin_Number);

   procedure Clear_Pins
     (Port : in Port_Number;
      Mask : in Pin_Mask);

   procedure Toggle_Pin
     (Port : in Port_Number;
      Pin  : in Pin_Number);

   procedure Toggle_Pins
     (Port : in Port_Number;
      Mask : in Pin_Mask);

   function Pin_To_Mask (Pin : Pin_Number) return Pin_Mask;
   pragma Inline (Pin_To_Mask);

   function Range_To_Mask (From, To : Pin_Number) return Pin_Mask;
   pragma Inline (Range_To_Mask);

private

   type Pin_Array is array (Pin_Number) of Boolean;
   pragma Pack (Pin_Array);
   for Pin_Array'Size use 32;

   type Pin_Mask is mod 2 ** 32;
   for Pin_Mask'Size use 32;

   type Pin_Control_Register is
      record
         RW     : Pin_Array;
         Set    : Pin_Mask;
         Clear  : Pin_Mask;
         Toggle : Pin_Mask;
         pragma Atomic (RW);
         pragma Atomic (Set);
         pragma Atomic (Clear);
         pragma Atomic (Toggle);
      end record;

   for Pin_Control_Register use
      record
         RW     at 0 range 0 .. 31;
         Set    at 4 range 0 .. 31;
         Clear  at 8 range 0 .. 31;
         Toggle at 12 range 0 .. 31;
      end record;

   for Pin_Control_Register'Size use 4 * 32;

   pragma Suppress_Initialization (Pin_Control_Register);

   type GPIO_Port_Interface is
      record
         GPIO_Enable                  : Pin_Control_Register;
         Peripheral_Mux_0             : Pin_Control_Register;
         Peripheral_Mux_1             : Pin_Control_Register;
         Reserved_A                   : Pin_Mask;
         Reserved_B                   : Pin_Mask;
         Reserved_C                   : Pin_Mask;
         Reserved_D                   : Pin_Mask;
         Output_Driver                : Pin_Control_Register;
         Output_Value                 : Pin_Control_Register;
         Pin_Value                    : Pin_Control_Register;
         Pull_Up_Enable               : Pin_Control_Register;
         Open_Drain_Enable            : Pin_Control_Register;
         Interrupt_Enable             : Pin_Control_Register;
         Interrupt_Mode_0             : Pin_Control_Register;
         Interrupt_Mode_1             : Pin_Control_Register;
         Glitch_Filter_Enable         : Pin_Control_Register;
         Interrupt_Flag_Enable        : Pin_Control_Register;
      end record;

   pragma Suppress_Initialization (GPIO_Port_Interface);

end GPIO_Controller;
