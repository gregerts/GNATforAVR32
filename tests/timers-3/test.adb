with Ada.Unchecked_Conversion, GNAT.IO, Utilities;
use GNAT.IO, Utilities;

package body Test is

   -----------------
   -- Definitions --
   -----------------

   function To_Count is new Ada.Unchecked_Conversion (Time, Count);
   function To_Count is new Ada.Unchecked_Conversion (Time_Span, Count);

   procedure Put is new Put_Hex (Data);

   T : Test_Event;

   ---------
   -- Set --
   ---------

   procedure Set (Event : in out Test_Event) is
   begin
      Event.X := Random (Event.Gen'Access);
      Event.Next := Event.Next + Microseconds (Event.X);
      Event.Set_Handler (Event.Next, Statistics.Handler'Access);
   end Set;

   --------------
   -- Overhead --
   --------------

   function Overhead (Event : Test_Event) return Count is
      Now : constant Time := Clock;
   begin
      pragma Assert (Now >= Event.Next);

      return To_Count (Now - Event.Next);
   end Overhead;

   ----------------
   -- Statistics --
   ----------------

   protected body Statistics is

      -------------
      -- Handler --
      -------------

      procedure Handler (Event : in out Timing_Event) is
         T : access Test_Event;
         O : Count;
      begin

         pragma Assert (not Done);
         pragma Assert (Event.Time_Of_Event = Time_First);
         pragma Assert (Event.Current_Handler = null);
         pragma Assert (Timing_Event'Class (Event) in Test_Event);

         T := Test_Event (Timing_Event'Class (Event))'Access;

         O := T.Overhead;

         D (L, 1) := Data (O);
         D (L, 2) := Data (T.X);
         D (L, 3) := Data (To_Count (T.Next) mod 2**16);

         L := L + 1;

         if L <= Data_Array'Last then
            T.Set;
         else
            Done := True;
         end if;

      end Handler;

      -----------
      -- Start --
      -----------

      procedure Start is
      begin

         L := Data_Array'First;

         T.Next := Clock + Milliseconds (500);
         T.Set;

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

      Reset (T.Gen, 1);

      New_Line;
      Put_Line ("SYNC");

      loop

         Statistics.Start;
         Statistics.Wait (DA);

         for I in Data_Array'Range (1) loop
            Put (DA (I, 1));
            Put (':');
            Put (DA (I, 2));
            Put (':');
            Put (DA (I, 3));
            New_Line;
         end loop;

      end loop;

   end Run;

end Test;
