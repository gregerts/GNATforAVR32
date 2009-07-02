with Ada.Interrupts.Names, Interrupt_States;
use Ada.Interrupts, Ada.Interrupts.Names, Interrupt_States;

package External_Interrupts is

   subtype External_Interrupt_Id is Interrupt_Id range EIM_0 .. EIM_7;

   type Level_Type is (High, Low);

   type Edge_Type is (Rising, Falling);

   type External_Interrupt (Id : External_Interrupt_Id)
      is abstract new Interrupt_State with private;

   procedure Initialize (S      : in out External_Interrupt;
                         Level  : Level_Type;
                         Filter : Boolean := True);

   procedure Initialize (S      : in out External_Interrupt;
                         Edge   : Edge_Type;
                         Filter : Boolean := True);

   procedure Enable (S : in out External_Interrupt);
   pragma Inline (Enable);

   procedure Disable (S : in out External_Interrupt);
   pragma Inline (Disable);

   procedure Clear (S : in out External_Interrupt);
   pragma Inline (Clear);

private

   type Mask is mod 2 ** 9;
   for Mask'Size use 32;

   type External_Interrupt (Id : External_Interrupt_Id)
      is abstract new Interrupt_State with
      record
         M : Mask := 0;
      end record;

end External_Interrupts;
