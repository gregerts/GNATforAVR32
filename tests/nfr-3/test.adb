with System, Ada.Real_Time, Ada.Interrupts.Names, Ada.Unchecked_Conversion,
  System.Storage_Elements, Utilities, Interfaces, GNAT.IO;
use System, Ada.Real_Time, Ada.Interrupts.Names, System.Storage_Elements,
  Utilities, Interfaces, GNAT.IO;

package body Test is

   ------------------------
   -- Test configuration --
   ------------------------

   D : constant := 10000;
   N : constant := 100;

   -----------------
   -- Definitions --
   -----------------

   type Data is mod 2 ** 32;
   for Data'Size use 32;

   procedure Put_Data is new Put_Hex (Data);

   R : array (1 .. N) of Data;

   ----------------------------
   -- Counter Value Register --
   ----------------------------

   type TC_Counter_Register is
      record
         Value  : Unsigned_16;
         Unused : Unsigned_16;
      end record;

   for TC_Counter_Register use
      record
         Value  at 0 range 16 .. 31;
         Unused at 0 range 0 .. 15;
      end record;

   for TC_Counter_Register'Size use 32;

   pragma Suppress_Initialization (TC_Counter_Register);

   --------------------------
   -- TC Channel Interface --
   --------------------------

   type TC_Channel_Interface is
      record
         Control           : Unsigned_32;
         Mode              : Unsigned_32;
         Unused_A          : Unsigned_32;
         Unused_B          : Unsigned_32;
         Counter           : TC_Counter_Register;
         RA                : TC_Counter_Register;
         RB                : TC_Counter_Register;
         RC                : TC_Counter_Register;
         Status            : Unsigned_32;
         Interrupt_Enable  : Unsigned_32;
         Interrupt_Disable : Unsigned_32;
         Interrupt_Mask    : Unsigned_32;
         pragma Atomic (Control);
         pragma Atomic (Mode);
         pragma Atomic (Counter);
         pragma Atomic (RA);
         pragma Atomic (RB);
         pragma Atomic (RC);
         pragma Atomic (Status);
         pragma Atomic (Interrupt_Enable);
         pragma Atomic (Interrupt_Disable);
         pragma Atomic (Interrupt_Mask);
      end record;

   pragma Suppress_Initialization (TC_Channel_Interface);

   TC : TC_Channel_Interface;
   for TC'Address use To_Address (16#FFFF_3800#);

   ----------------
   -- Statistics --
   ----------------

   protected Statistics is

      procedure Initialize;
      procedure Start;
      entry Wait;

      pragma Interrupt_Priority (System.Interrupt_Priority'First);

   private

      procedure Handler;
      pragma Attach_Handler (Handler, TC_0);

      L : Integer;
      Done : Boolean := False;

   end Statistics;

   ----------------
   -- Statistics --
   ----------------

   protected body Statistics is

      ----------------
      -- Initialize --
      ----------------

      procedure Initialize is
      begin

         --  Wave mode with autmoatic RC trigger, clk / 2
         TC.Mode := 16#0000_C001#;

         --  Enable RC compare interrupt
         TC.Interrupt_Enable := 16#0000_0010#;

         --  Set RC to D
         TC.RC.Value := D;

      end Initialize;

      -----------
      -- Start --
      -----------

      procedure Start is
      begin
         L := R'First;
         TC.Control := 5; --  Enable clock and sync
      end Start;

      -------------
      -- Handler --
      -------------

      procedure Handler is
         C : constant Unsigned_16 := TC.Counter.Value;
         S : constant Unsigned_32 := TC.Status;
      begin

         R (L) := Data (C);
         L := L + 1;

         if L > R'Last then
            Done := True;
            TC.Control := 2; --  Disable clock
         end if;

      end Handler;

      ----------
      -- Wait --
      ----------

      entry Wait when Done is
      begin
         Done := False;
      end Wait;

   end Statistics;

   ---------
   -- Run --
   ---------

   procedure Run is
   begin

      New_Line;
      Put_Line ("SYNC");
      Put (2);
      New_Line;

      Statistics.Initialize;

      loop
         Statistics.Start;
         Statistics.Wait;

         for I in R'Range loop
            Put_Data (R (I));
            Put (':');
            Put_Data (R (I));
            New_Line;
         end loop;

      end loop;

   end Run;

end Test;
