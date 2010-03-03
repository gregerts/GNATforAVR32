with System;
with Ada.Real_Time.Timing_Events;
with Quick_Random;

use Ada.Real_Time;
use Ada.Real_Time.Timing_Events;

generic
   A, B, C, M : Natural;
package Test is

   package T_Random is new Quick_Random (A, B);
   use T_Random;

   type Stat is (Expired, D_Min, D_Max, D_Sum);

   type Count is mod 2**64;
   for Stat'Size use 64;

   type Stat_Array is array (Stat) of Count;
   type Stat_Access is access all Stat_Array;

   type Hist_Array is array (0 .. 31) of Count;
   type Hist_Access is access all Hist_Array;

   ----------------
   -- Statistics --
   ----------------

   protected Statistics is

      pragma Priority (System.Interrupt_Priority'Last);

      procedure Handler (Event : in out Timing_Event);

      procedure Start;

      entry Wait (SA : out Stat_Access;
                  HA : out Hist_Access);

   private
      S : aliased Stat_Array;
      H : aliased Hist_Array;
      Done : Boolean := False;
   end Statistics;

   ----------------
   -- Test_Event --
   ----------------

   type Test_Event is new Timing_Event with
      record
         Next : Time;
         Gen : aliased Generator;
      end record;

   procedure Set (Event : in out Test_Event);

   function D (Event : Test_Event) return Count;

   T : Test_Event;

   ---------
   -- Run --
   ---------

   procedure Run;
   pragma No_Return (Run);

end Test;
