with Ada.Interrupts;

package Ada.Execution_Time.Interrupts is

   function Clock (I : Ada.Interrupts.Interrupt_ID) return CPU_Time;

   function Supported (I : Ada.Interrupts.Interrupt_ID) return Boolean;

end Ada.Execution_Time.Interrupts;
