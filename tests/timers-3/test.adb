with Ada.Unchecked_Conversion;
with GNAT.IO;
with Utilities;

use GNAT.IO;
use Utilities;

package body Test is

   function To_Count is new Ada.Unchecked_Conversion (Time_Span, Count);

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
         C : Boolean;

      begin

         pragma Assert (not Done);
         pragma Assert (Event.Time_Of_Event = Time_First);
         pragma Assert (Event.Current_Handler = null);
         pragma Assert (Timing_Event'Class (Event) in Test_Event);

         This := Test_Event (Timing_Event'Class (Event))'Access;

         D := This.D;

         S (D_Min)   := Count'Min (D, S (D_Min));
         S (D_Max)   := Count'Max (D, S (D_Max));
         S (D_Sum)   := S (D_Sum)   + D;
         S (D_Sum_2) := S (D_Sum_2) + D*D;
         S (Expired) := S (Expired) + 1;

         if S (Expired) < Count (M) then

            This.Other.Cancel_Handler (C);

            pragma Assert (C);

            S (Cancelled) := S (Cancelled) + 1;

            This.Set;
            This.Other.Set;

            S (Set) := S (Set) + 2;

         else

            for I in Timers'Range loop

               Timers (I).Cancel_Handler (C);

               if C then
                  S (Cancelled) := S (Cancelled) + 1;
               end if;

            end loop;

            Done := True;

         end if;

      end Handler;

      -----------
      -- Start --
      -----------

      procedure Start is
         First : constant Time := Clock + Milliseconds (100);
      begin

         for I in Timers'Range loop
            Timers (I).Next := First;
            Timers (I).Set;
         end loop;

         S := (Set   => Count (N),
               D_Min => Count'Last,
               D_Max => Count'First,
               others => 0);

         Done := False;

      end Start;

      ----------
      -- Wait --
      ----------

      entry Wait (SA : out Stat_Access) when Done is
      begin
         SA := S'Access;
      end Wait;

   end Statistics;

   ---------
   -- Set --
   ---------

   procedure Set (Event : in out Test_Event)
   is
   begin
      Event.Next := Event.Next + Microseconds (Random (Gen'Access));

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
   begin

      Reset (Gen, 2*A + 3*B + 5*N + 7*M);

      for I in Timers'Range loop

         if I mod 2 = 1 then
            Timers (I).Other := Timers (I + 1)'Access;
         else
            Timers (I).Other := Timers (I - 1)'Access;
         end if;

      end loop;

      New_Line;
      Put_Line ("SYNC");

      loop

         Statistics.Start;

         Statistics.Wait (SA);

         for I in Stat loop

            Put (SA (I));

            if I = Stat'Last then
               New_Line;
            else
               Put (':');
            end if;

         end loop;

      end loop;

   end Run;

end Test;
