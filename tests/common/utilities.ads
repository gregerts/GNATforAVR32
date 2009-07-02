package Utilities is

   procedure Busy_Wait (C : Natural);
   --  Busy wait for the given number of microseconds

   generic
      type Item_Type is private;
      Leading_Zeroes : Boolean := False;
   procedure Put_Hex (Item : Item_Type);
   --  Outputs a generic item as a hexadecimal string

end Utilities;
