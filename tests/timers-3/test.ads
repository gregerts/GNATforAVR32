with System, Ada.Real_Time.Timing_Events, Quick_Random;
use System, Ada.Real_Time, Ada.Real_Time.Timing_Events;

generic
   A, B, N : Natural;
package Test is

   package T_Random is new Quick_Random (A, B);
   use T_Random;

   type Count is mod 2**64;
   for Count'Size use 64;

   type Data is mod 2**16;
   for Data'Size use 16;

   type Data_Array is array (1 .. N, 1 .. 3) of Data;
   type Data_Access is access all Data_Array;

   ----------------
   -- Test_Event --
   ----------------

   type Test_Event is new Timing_Event with
      record
         X : Integer;
         Next : Time;
         Gen : aliased Generator;
      end record;

   procedure Set (Event : in out Test_Event);

   function Overhead (Event : Test_Event) return Count;

   ----------------
   -- Statistics --
   ----------------

   protected Statistics is

      pragma Priority (System.Interrupt_Priority'Last);

      procedure Handler (Event : in out Timing_Event);

      procedure Start;

      entry Wait (DA : out Data_Access);

   private
      L : Integer;
      D : aliased Data_Array;
      Done : Boolean := False;
   end Statistics;

   ---------
   -- Run --
   ---------

   procedure Run;
   pragma No_Return (Run);

end Test;
