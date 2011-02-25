package body Ada.Execution_Time.Interrupts is

   package TMU  renames System.BB.TMU;

   function Clock (I : Ada.Interrupts.Interrupt_ID) return CPU_Time is
   begin
      return CPU_Time
        (TMU.Execution_Time (TMU.Interrupt_Clock (TMU.Interrupt_ID (I))));
   end Clock;

   function Supported (I : Ada.Interrupts.Interrupt_ID) return Boolean is
      pragma Unreferenced (I);
   begin
      return True;
   end Supported;

end Ada.Execution_Time.Interrupts;
