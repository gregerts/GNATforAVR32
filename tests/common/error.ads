with Ada.Exceptions;

package Error is

   procedure Last_Chance_Handler (Message : access String);
   pragma No_Return (Last_Chance_Handler);
   pragma Export (Ada, Last_Chance_Handler, "__gnat_last_chance_handler");
   --  Last chance handler for use when testing the system.

end Error;
