with Ada.Unchecked_Conversion, GNAT.IO, Utilities;
use GNAT.IO, Utilities;

package body Test is

   -----------------
   -- Definitions --
   -----------------

   package T_Random is new Quick_Random (A, B);
   use T_Random;

   type Count is mod 2**64;
   for Count'Size use 64;

   type Data is mod 2**16;
   for Data'Size use 16;

   type Data_Array is array (1 .. N, 1 .. 3) of Data;
   type Data_Access is access all Data_Array;

   function To_Count is new Ada.Unchecked_Conversion (Time, Count);
   function To_Count is new Ada.Unchecked_Conversion (Time_Span, Count);

   procedure Put is new Put_Hex (Data);

   ----------------
   -- Statistics --
   ----------------

   protected Statistics is

      pragma Priority (System.Interrupt_Priority'Last);

      procedure Handler (Event : in out Timing_Event);

      procedure Start;

      entry Wait (DA : out Data_Access);

   private
      T : Timing_Event;
      L : Integer;
      X : Integer;
      D : aliased Data_Array;
      Gen : aliased Generator;
      Next : Time;
      Done : Boolean := False;
      First : Boolean := True;
   end Statistics;

   ----------------
   -- Statistics --
   ----------------

   protected body Statistics is

      -------------
      -- Handler --
      -------------

      procedure Handler (Event : in out Timing_Event) is
         Now : constant Time := Clock;
      begin

         pragma Assert (Next <= Now);
         pragma Assert (To_Count (Now - Next) < 2**16);

         D (L, 1) := Data (To_Count (Now - Next));
         D (L, 2) := Data (X);
         D (L, 3) := D (L, 1) xor D (L, 2);

         L := L + 1;

         if L <= Data_Array'Last then
            X := Random (Gen'Access);
            Next := Next + Microseconds (X);
            T.Set_Handler (Next, Handler'Access);
         else
            Done := True;
         end if;

      end Handler;

      -----------
      -- Start --
      -----------

      procedure Start is
      begin

         if First then
            Reset (Gen, 1);
            First := False;
         end if;

         L := Data_Array'First;

         X := Random (Gen'Access);
         Next := Clock + Microseconds (1000 + X);
         T.Set_Handler (Next, Handler'Access);

         Done := False;

      end Start;

      ----------
      -- Wait --
      ----------

      entry Wait (DA : out Data_Access) when Done is
      begin
         DA := D'Access;
      end Wait;

   end Statistics;

   ---------
   -- Run --
   ---------

   procedure Run is
      DA : Data_Access;
   begin

      New_Line;
      Put_Line ("SYNC");

      loop

         Statistics.Start;
         Statistics.Wait (DA);

         for I in Data_Array'Range (1) loop
            for J in Data_Array'Range (2) loop
               Put (DA (I, J));
               if J < Data_Array'Last (2) then
                  Put (':');
               else
                  New_Line;
               end if;
            end loop;
         end loop;

      end loop;

   end Run;

end Test;
