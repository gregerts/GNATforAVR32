package body Ada.Execution_Time.Interrupts is

   package SBT renames System.BB.Time;

   function Clock (I : Ada.Interrupts.Interrupt_ID) return CPU_Time is
      use type SBT.Clock_Id;
      C : constant SBT.Clock_Id := SBT.Interrupt_Clock (SBT.Interrupt_ID (I));
   begin
      if C = null then
         return CPU_Time_First;
      else
         return CPU_Time (SBT.Time_Of_Clock (C));
      end if;
   end Clock;

   function Supported (I : Ada.Interrupts.Interrupt_ID) return Boolean is
      pragma Unreferenced (I);
   begin
      return True;
   end Supported;

end Ada.Execution_Time.Interrupts;
