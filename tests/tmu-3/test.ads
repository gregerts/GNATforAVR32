with System;
with Ada.Real_Time.Timing_Events;
with Ada.Execution_Time.Timers;
with Ada.Task_Identification;
with Quick_Random;

use Ada.Real_Time;
use Ada.Real_Time.Timing_Events;
use Ada.Task_Identification;
use Ada.Execution_Time;
use Ada.Execution_Time.Timers;

generic
   A, B, M : Natural;
package Test is

   Size : constant := 2048;

   package T_Random is new Quick_Random (A, B);
   use T_Random;

   type Stat is (Set, Cancelled, Expired,
                 D_Min, D_Max, D_Sum, D_Sum_2);

   type Count is mod 2**64;
   for Stat'Size use 64;

   type Stat_Array is array (Stat) of Count;
   type Stat_Access is access all Stat_Array;

   ------------
   -- Worker --
   ------------

   protected Statistics is

      pragma Priority (System.Interrupt_Priority'Last);

      procedure Handler (TM : in out Timer);

      procedure Start;

      entry Wait (SA : out Stat_Access);

   private
      S : aliased Stat_Array;
      Done : Boolean := False;
   end Statistics;

   ----------------
   -- Controller --
   ----------------

   task Controller is
      pragma Priority (System.Priority'Last);
      pragma Storage_Size (Size);
   end Controller;

   ---------------------
   -- Test_Timer --
   ---------------------

   type Test_Timer (T : not null access constant Task_Id) is
     new Timer (T) with
      record
         Next  : CPU_Time;
         Other : access Test_Timer;
         Gen   : aliased Generator;
      end record;

   procedure Set (TM : in out Test_Timer);

   function D (TM : Test_Timer) return Count;

   type Test_Timer_Access is access all Test_Timer'Class;

   --------------
   -- Periodic --
   --------------

   task type Periodic
     (P : System.Priority;
      T : Natural;
      C : Natural)
   is
      pragma Priority (P);
      pragma Storage_Size (Size);
   end Periodic;

   T_A : Periodic (90,  50_000,  5_000);
   T_B : Periodic (80, 100_000, 10_000);
   T_C : Periodic (70, 200_000, 20_000);
   T_D : Periodic (60, 400_000, 40_000);

   Id_A : aliased Task_Id := T_A'Identity;
   Id_B : aliased Task_Id := T_B'Identity;
   Id_C : aliased Task_Id := T_C'Identity;
   Id_D : aliased Task_Id := T_D'Identity;

   TM_A : aliased Test_Timer (Id_A'Access);
   TM_B : aliased Test_Timer (Id_B'Access);
   TM_C : aliased Test_Timer (Id_C'Access);
   TM_D : aliased Test_Timer (Id_D'Access);

   Timers : array (1 .. 4) of Test_Timer_Access := (TM_A'Access,
                                                    TM_B'Access,
                                                    TM_C'Access,
                                                    TM_D'Access);

end Test;
