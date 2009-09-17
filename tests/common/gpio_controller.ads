with System, Interfaces;
use Interfaces;

package GPIO_Controller is

   type Port_Interface is limited private;

   type Port_Id is not null access all Port_Interface;

   Port_A : constant Port_Id;
   Port_B : constant Port_Id;
   Port_C : constant Port_Id;
   Port_X : constant Port_Id;

   subtype Pin_Number is Natural range 0 .. 31;
   subtype Pin_Mask   is Unsigned_32;

   type Pin_Peripheral is (Peripheral_A, Peripheral_B, Peripheral_C);
   type Pin_Edge       is (Both, Rising, Falling);

   procedure Configure_GPIO
     (Port       : Port_Id;
      Mask       : Pin_Mask;
      Output     : Boolean := False;
      Open_Drain : Boolean := False;
      Pull_Up    : Boolean := False);

   procedure Configure_Peripheral
     (Port       : Port_Id;
      Mask       : Pin_Mask;
      Peripheral : Pin_Peripheral);

   procedure Enable_Interrupt
     (Port     : Port_Id;
      Mask     : Pin_Mask;
      Edge     : Pin_Edge := Both;
      Deglitch : Boolean  := False);

   procedure Disable_Interrupt
     (Port : Port_Id;
      Mask : Pin_Mask);

   function Get_Pin_Value
     (Port : Port_Id;
      Pin  : Pin_Number)
     return Boolean;

   function Get_Pin_Output_Value
     (Port : Port_Id;
      Pin  : Pin_Number)
     return Boolean;

   procedure Set_Pin
     (Port  : Port_Id;
      Pin   : Pin_Number);

   procedure Set_Pins
     (Port  : Port_Id;
      Mask  : Pin_Mask);

   procedure Clear_Pin
     (Port : Port_Id;
      Pin  : Pin_Number);

   procedure Clear_Pins
     (Port : Port_Id;
      Mask : Pin_Mask);

   procedure Toggle_Pin
     (Port : Port_Id;
      Pin  : Pin_Number);

   procedure Toggle_Pins
     (Port : Port_Id;
      Mask : Pin_Mask);

   function Pin_To_Mask (Pin : Pin_Number) return Pin_Mask;

   function Range_To_Mask (From, To : Pin_Number) return Pin_Mask;


private

   pragma Inline (Set_Pin);
   pragma Inline (Set_Pins);
   pragma Inline (Clear_Pin);
   pragma Inline (Clear_Pins);
   pragma Inline (Toggle_Pin);
   pragma Inline (Toggle_Pins);

   pragma Inline_Always (Pin_To_Mask);
   pragma Inline_Always (Range_To_Mask);

   type Pin_Control_Register is
      record
         RW     : Pin_Mask;
         Set    : Pin_Mask;
         Clear  : Pin_Mask;
         Toggle : Pin_Mask;
         pragma Atomic (RW);
         pragma Atomic (Set);
         pragma Atomic (Clear);
         pragma Atomic (Toggle);
      end record;

   pragma Suppress_Initialization (Pin_Control_Register);

   type Port_Interface is limited
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

   pragma Suppress_Initialization (Port_Interface);

   PA : aliased Port_Interface;
   PB : aliased Port_Interface;
   PC : aliased Port_Interface;
   PX : aliased Port_Interface;

   for PA'Address use System'To_Address (16#FFFF_1000#);
   for PB'Address use System'To_Address (16#FFFF_1100#);
   for PC'Address use System'To_Address (16#FFFF_1200#);
   for PX'Address use System'To_Address (16#FFFF_1300#);

   Port_A : constant Port_Id := PA'Access;
   Port_B : constant Port_Id := PB'Access;
   Port_C : constant Port_Id := PC'Access;
   Port_X : constant Port_Id := PX'Access;

end GPIO_Controller;
