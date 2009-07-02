with System;

package body External_Interrupts is

   type EIM_Control is
     record
        Enable  : Mask;
        Disable : Mask;
        I_Mask  : Mask;
        Status  : Mask;
        Clear   : Mask;
        Mode    : Mask;
        Edge    : Mask;
        Level   : Mask;
        Filter  : Mask;
        Test    : Mask;
        Asynch  : Mask;
        Scan    : Mask;
        Interrupt_Enable  : Mask;
        Interrupt_Disable : Mask;
        Interrupt_Control : Mask;
     end record;

   pragma Suppress_Initialization (EIM_Control);

   Control : EIM_Control;
   for Control'Address use System'To_Address (16#FFFF0D80#);

   pragma Volatile (Control);

   function To_Mask (Id : External_Interrupt_Id) return Mask;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (S      : in out External_Interrupt;
      Level  : Level_Type;
      Filter : Boolean := True)
   is
   begin

      S.M := To_Mask (S.Id);

      pragma Assert (S.M > 0);

      Control.Mode := Control.Mode or S.M;

      if Level = Low then
         Control.Level := Control.Level and (not S.M);
      else
         Control.Level := Control.Level or S.M;
      end if;

      if Filter then
         Control.Filter := Control.Filter or S.M;
      else
         Control.Filter := Control.Filter and (not S.M);
      end if;

   end Initialize;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (S      : in out External_Interrupt;
      Edge   : Edge_Type;
      Filter : Boolean := True)
   is
   begin

      S.M := To_Mask (S.Id);

      pragma Assert (S.M > 0);

      Control.Mode := Control.Mode and not (S.M);

      if Edge = Falling then
         Control.Edge := Control.Edge and (not S.M);
      else
         Control.Edge := Control.Edge or S.M;
      end if;

      if Filter then
         Control.Filter := Control.Filter or S.M;
      else
         Control.Filter := Control.Filter and (not S.M);
      end if;

   end Initialize;

   ------------
   -- Enable --
   ------------

   procedure Enable (S : in out External_Interrupt) is
   begin
      Control.Enable           := S.M;
      Control.Interrupt_Enable := S.M;
   end Enable;

   -------------
   -- Disable --
   -------------

   procedure Disable (S : in out External_Interrupt) is
   begin
      Control.Disable           := S.M;
      Control.Interrupt_Disable := S.M;
   end Disable;

   -----------
   -- Clear --
   -----------

   procedure Clear (S : in out External_Interrupt) is
   begin
      Control.Clear := S.M;
   end Clear;

   -------------
   -- To_Mask --
   -------------

   function To_Mask (Id : External_Interrupt_Id) return Mask is
      M : constant array (External_Interrupt_Id) of Mask
        := (1, 2, 4, 8, 16, 32, 64, 128);
   begin
      return M (Id);
   end To_Mask;

end External_Interrupts;
