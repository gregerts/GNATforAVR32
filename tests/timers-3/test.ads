with System;
with Ada.Real_Time.Timing_Events;
with Quick_Random;

use Ada.Real_Time;
use Ada.Real_Time.Timing_Events;

generic
   A, B, N, M : Natural;
package Test is

   package T_Random is new Quick_Random (A, B);
   use T_Random;

   type Stat is (Set, Cancelled, Expired, D_Min, D_Max, D_Sum, TT, ET);

   type Count is mod 2**64;
   for Stat'Size use 64;

   type Stat_Array is array (Stat) of Count;
   type Stat_Access is access all Stat_Array;

   ----------------
   -- Statistics --
   ----------------

   protected Statistics is

      pragma Priority (System.Interrupt_Priority'Last);

      procedure Handler (Event : in out Timing_Event);

      procedure Start;

      entry Wait (SA : out Stat_Access);

   private
      S : aliased Stat_Array;
      Done : Boolean := False;
   end Statistics;

   ----------------
   -- Test_Event --
   ----------------

   type Test_Event is new Timing_Event with
      record
         Next : Time;
         Other : access Test_Event;
         Gen : aliased Generator;
      end record;

   procedure Set (Event : in out Test_Event);

   function D (Event : Test_Event) return Count;

   Timers : array (1 .. N) of aliased Test_Event;

   ---------
   -- Run --
   ---------

   procedure Run;
   pragma No_Return (Run);

end Test;
