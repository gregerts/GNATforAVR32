with Ada.Unchecked_Conversion;
with Ada.Execution_Time;
with System;
with GNAT.IO;
with Utilities;
with Seeds;

use GNAT.IO;
use Ada.Execution_Time;
use System;
use Utilities;
use Seeds;

package body Test is

   function To_Count is new Ada.Unchecked_Conversion (Time, Count);
   function To_Count is new Ada.Unchecked_Conversion (Time_Span, Count);
   function To_Count is new Ada.Unchecked_Conversion (CPU_Time, Count);

   procedure Put is new Put_Hex (Count);

   ----------------
   -- Statistics --
   ----------------

   protected body Statistics is

      -------------
      -- Handler --
      -------------

      procedure Handler (Event : in out Timing_Event) is
         This : access Test_Event;
         D : Count;
         I : Integer;
      begin

         pragma Assert (not Done);
         pragma Assert (Event.Time_Of_Event = Time_First);
         pragma Assert (Event.Current_Handler = null);
         pragma Assert (Timing_Event'Class (Event) in Test_Event);

         This := Test_Event (Timing_Event'Class (Event))'Access;

         D := This.D;
         I := Integer'Min (H'Last, ((H'Last + 1) * Integer(D)) / C);

         H (I) := H (I) + 1;

         S (Expired) := S (Expired) + 1;

         S (D_Min)   := Count'Min (D, S (D_Min));
         S (D_Max)   := Count'Max (D, S (D_Max));
         S (D_Sum)   := S (D_Sum) + D;

         if S (Expired) < Count (M) then
            This.Set;
         else
            Done := True;
         end if;

      end Handler;

      -----------
      -- Start --
      -----------

      procedure Start is
         First : constant Time := Clock + Milliseconds (100);
      begin

         T.Next := First;
         T.Set;

         S := (D_Min => Count'Last,
               D_Max => Count'First,
               others => 0);

         H := (others => 0);

         Done := False;

      end Start;

      ----------
      -- Wait --
      ----------

      entry Wait (SA : out Stat_Access;
                  HA : out Hist_Access) when Done is
      begin
         SA := S'Access;
         HA := H'Access;
      end Wait;

   end Statistics;

   ---------
   -- Set --
   ---------

   procedure Set (Event : in out Test_Event)
   is
   begin
      Event.Next := Event.Next + Microseconds (Random (Event.Gen'Access));
      Event.Set_Handler (Event.Next, Statistics.Handler'Access);
   end Set;

   -------
   -- D --
   -------

   function D (Event : Test_Event) return Count is
      T : constant Time := Clock;
   begin
      pragma Assert (T >= Event.Next);

      return To_Count (T - Event.Next);
   end D;

   ---------
   -- Run --
   ---------

   procedure Run is
      SA : Stat_Access;
      HA : Hist_Access;
   begin

      Reset (T.Gen, Seed (1));

      New_Line;
      Put_Line ("SYNC");

      loop

         Statistics.Start;

         Statistics.Wait (SA, HA);

         for I in Stat loop

            Put (SA (I));
            Put (':');

         end loop;

         for I in Hist_Array'Range loop

            Put (HA (I));

            if I = Hist_Array'Last then
               New_Line;
            else
               Put (':');
            end if;

         end loop;


      end loop;

   end Run;

end Test;
