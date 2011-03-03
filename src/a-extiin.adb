package body Ada.Execution_Time.Interrupts is

   package TMU  renames System.BB.TMU;

   function Clock (I : Ada.Interrupts.Interrupt_ID) return CPU_Time is
      use type TMU.Clock_Id;
      C : constant TMU.Clock_Id := TMU.Interrupt_Clock (TMU.Interrupt_ID (I));
   begin
      if C = null then
         return CPU_Time_First;
      else
         return CPU_Time (TMU.Execution_Time (C));
      end if;
   end Clock;

   function Supported (I : Ada.Interrupts.Interrupt_ID) return Boolean is
      pragma Unreferenced (I);
   begin
      return True;
   end Supported;

end Ada.Execution_Time.Interrupts;
