with Ada.Unchecked_Conversion;
with GNAT.IO;
with Utilities;

use GNAT.IO;
use Utilities;

package body Test is

   Epoch : constant Time := Time_First + Milliseconds (100);

   function To_Count is new Ada.Unchecked_Conversion (CPU_Time, Count);

   procedure Put is new Put_Hex (CPU_Time);
   procedure Put is new Put_Hex (Count);

   ----------------
   -- Statistics --
   ----------------

   protected body Statistics is

      -------------
      -- Handler --
      -------------

      procedure Handler (TM : in out Timer) is

         subtype TC is Timer'Class;

         D : Count;
         C : Boolean;

         Other : access Test_Timer;

      begin

         pragma Assert (TC (TM) in Test_Timer);
         pragma Assert (TM.Time_Remaining = Time_Span_Zero);
         pragma Assert (TM.Current_Handler = null);
         pragma Assert (not Done);

         D := Test_Timer (TC (TM)).D;

         S (D_Min)   := Count'Min (D, S (D_Min));
         S (D_Max)   := Count'Max (D, S (D_Max));
         S (D_Sum)   := S (D_Sum)   + D;
         S (D_Sum_2) := S (D_Sum_2) + D*D;
         S (Expired) := S (Expired) + 1;

         if S (Expired) < Count (M) then

            Other := Test_Timer (TC (TM)).Other;

            Other.Cancel_Handler (C);

            pragma Assert (C);

            S (Cancelled) := S (Cancelled) + 1;

            Test_Timer (TC (TM)).Set;
            Other.Set;

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
      begin

         for I in Timers'Range loop
            Timers (I).Set;
         end loop;

         S := (Set   => Count (Timers'Length),
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

   procedure Set (TM : in out Test_Timer)
   is
   begin
      TM.Next := Clock (TM.T.all) + Microseconds (Random (TM.Gen'Access));

      TM.Set_Handler (TM.Next, Statistics.Handler'Access);
   end Set;

   -------
   -- D --
   -------

   function D (TM : Test_Timer) return Count is
      T : constant CPU_Time := Clock (TM.T.all);
   begin
      pragma Assert (T >= TM.Next);

      return To_Count (T) - To_Count (TM.Next);
   end D;

   ----------------
   -- Controller --
   ----------------

   task body Controller is
      SA : Stat_Access;
   begin

      for I in Timers'Range loop

         Reset (Timers (I).Gen);

         if I mod 2 = 1 then
            Timers (I).Other := Timers (I + 1);
         else
            Timers (I).Other := Timers (I - 1);
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

   end Controller;

   --------------
   -- Periodic --
   --------------

   task body Periodic is
      Next : Time := Epoch;
   begin
      loop
         delay until Next;
         Busy_Wait (C);
         Next := Next + Microseconds (T);
      end loop;
   end Periodic;

end Test;
