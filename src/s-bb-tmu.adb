------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                         S Y S T E M . B B . T M U                        --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--               Copyright (C) 2007-2009 Kristoffer N. Gregertsen           --
--                                                                          --
-- GNARL is free software; you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. GNARL is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
--
--
--
--
--
--
--
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by Ada Core Technologies, Inc.     --
--                                                                          --
-- The porting of GNARL to bare board  targets was initially  developed  by --
-- the Real-Time Systems Group at the Technical University of Madrid.       --
--                                                                          --
------------------------------------------------------------------------------

with System.BB.CPU_Primitives;
with System.BB.Parameters;
with System.BB.Threads;

package body System.BB.TMU is

   package CPU renames System.BB.CPU_Primitives;
   package SBP renames System.BB.Parameters;

   use type CPU.Word;

   subtype Word is CPU.Word;

   type Pool_Index is range 0 .. SBP.Interrupt_Clocks;
   for Pool_Index'Size use 8;

   type Stack_Index is new Interrupts.Interrupt_Level;

   -----------------------
   -- Local definitions --
   -----------------------

   Max_Compare : constant := Word'Last - 2**16;
   --  Maximal value set to COMPARE register

   Pool : array (Pool_Index) of aliased Clock_Descriptor;
   --  Pool of clocks

   Last : Pool_Index := 0;
   --  Pointing to last allocated clock in pool

   Idle : constant Clock_Id := Pool (0)'Access;
   --  Clock of the pseudo idle thread

   Lookup : array (Interrupt_ID) of Pool_Index;
   --  Array for translating interrupt IDs to interrupt clock index

   Stack : array (Stack_Index) of Clock_Id;
   --  Stack of timers

   Top : Stack_Index;
   --  Index of stack top

   -----------------------
   -- Local subprograms --
   -----------------------

   function Active (Clock : Clock_Id) return Boolean;
   pragma Inline_Always (Active);
   --  Returns true when the given clock is active (running)

   procedure Clear (TM : Timer_Id);
   pragma Inline_Always (Clear);
   --  Clears the given timer

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID);
   --  Handler for the COMPARE interrupt

   procedure Context_Switch (First : Thread_Id);
   pragma Export (Asm, Context_Switch, "tmu_context_switch");
   --  Changes TMU context to first thread

   function Get_Compare (Clock : Clock_Id) return Word;
   pragma Inline (Get_Compare);
   --  Computes the COMPARE value for a clock

   procedure Initialize_Clock (Clock : Clock_Id);
   --  Initializes the given clock

   procedure Swap_Clock (A, B : Clock_Id);
   pragma Inline_Always (Swap_Clock);
   --  Swaps active clock from A to B

   ------------
   -- Active --
   ------------

   function Active (Clock : Clock_Id) return Boolean is
   begin
      return Clock = Stack (Top);
   end Active;

   ------------
   -- Cancel --
   ------------

   procedure Cancel (TM : Timer_Id) is
   begin

      pragma Assert (TM /= null);

      if TM.Set then

         Clear (TM);

         if Active (TM.Clock) then
            CPU.Adjust_Compare (Max_Compare);
         end if;

      end if;

   end Cancel;

   -----------
   -- Clear --
   -----------

   procedure Clear (TM : Timer_Id) is
   begin
      TM.Timeout := CPU_Time'Last;
      TM.Set := False;
   end Clear;

   -----------
   -- Clock --
   -----------

   function Clock (TM : Timer_Id) return Clock_Id is
   begin
      return TM.Clock;
   end Clock;

   ---------------------
   -- Compare_Handler --
   ---------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID) is

      --  Only the clock second from the top of the stack can have
      --  expired as timeouts are not allowed for highest priority.

      Clock : constant Clock_Id := Stack (Top - 1);
      TM    : constant Timer_Id := Clock.TM;

   begin

      pragma Assert (Id = Peripherals.COMPARE);

      --  Clear TM and call handler if it has expired

      if TM /= null and then TM.Timeout <= Clock.Base_Time then
         Clear (TM);
         TM.Handler (TM.Data);
      end if;

   end Compare_Handler;

   --------------------
   -- Context_Switch --
   --------------------

   procedure Context_Switch (First : Thread_Id) is
      A : constant Clock_Id := Stack (0);
      B : constant Clock_Id := First.Active_Clock;

   begin
      pragma Assert (Top = 0 and A /= B);

      Swap_Clock (A, B);
      Stack (0) := B;

   end Context_Switch;

   ----------------
   -- Enter_Idle --
   ----------------

   procedure Enter_Idle (Id : Thread_Id) is
      A : constant Clock_Id := Id.Active_Clock;
      B : constant Clock_Id := Idle;

   begin
      pragma Assert (Top = 0 and then A = Stack (0));
      pragma Assert (A = Id.Clock'Access);

      Swap_Clock (A, B);

      Id.Active_Clock := B;
      Stack (0) := B;

   end Enter_Idle;

   ---------------------
   -- Enter_Interrupt --
   ---------------------

   procedure Enter_Interrupt (Id : Interrupt_ID) is
      A : constant Clock_Id := Stack (Top);
      B : constant Clock_Id := Pool (Lookup (Id))'Access;

   begin
      pragma Assert (Top < Stack'Last);
      pragma Assert (Lookup (Id) > 0);

      Swap_Clock (A, B);

      Top         := Top + 1;
      Stack (Top) := B;

   end Enter_Interrupt;

   --------------------
   -- Execution_Time --
   --------------------

   function Execution_Time (Clock : Clock_Id) return CPU_Time is
      B : CPU_Time;
      C : Word;

   begin
      pragma Assert (Clock /= null);

      --  If clock is not active return base time

      if not Active (Clock) then
         return Clock.Base_Time;
      end if;

      --  Else the time of clock is sum of base time and count

      loop
         B := Clock.Base_Time;
         C := CPU.Get_Count;
         exit when B = Clock.Base_Time;
      end loop;

      return B + CPU_Time (C);

   end Execution_Time;

   -----------------
   -- Get_Compare --
   -----------------

   function Get_Compare (Clock : Clock_Id) return Word is
      T  : constant CPU_Time := Clock.Base_Time;
      TM : constant Timer_Id := Clock.TM;
   begin

      if TM = null or else TM.Timeout > (T + Max_Compare) then
         return Max_Compare;
      elsif TM.Timeout > T then
         return Word (TM.Timeout - T);
      else
         return 1;
      end if;

   end Get_Compare;

   ----------------------
   -- Initialize_Clock --
   ----------------------

   procedure Initialize_Clock (Clock : Clock_Id) is
   begin
      Clock.all := (Base_Time => CPU_Time'First, TM => null);
   end Initialize_Clock;

   --------------------------------
   -- Initialize_Interrupt_Clock --
   --------------------------------

   procedure Initialize_Interrupt_Clock (Id : Interrupt_ID) is
   begin
      pragma Assert (Id /= Interrupts.No_Interrupt);
      pragma Assert (Lookup (Id) = 0);
      pragma Assert (Last < Pool_Index'Last);

      Last := Last + 1;
      Lookup (Id) := Last;

      Initialize_Clock (Pool (Last)'Access);

   end Initialize_Interrupt_Clock;

   -----------------------------
   -- Initialize_Thread_Clock --
   -----------------------------

   procedure Initialize_Thread_Clock (Id : Thread_Id) is
   begin
      pragma Assert (Id /= null and then Id.Active_Clock = null);

      Id.Active_Clock := Id.Clock'Access;
      Initialize_Clock (Id.Active_Clock);

   end Initialize_Thread_Clock;

   ----------------------
   -- Initialize_Timer --
   ----------------------

   procedure Initialize_Timer
     (TM      : Timer_Id;
      Clock   : Clock_Id;
      Handler : not null Timer_Handler;
      Data    : System.Address;
      Success : out Boolean)
   is
   begin
      pragma Assert (TM /= null and then TM.Clock = null);

      if Clock /= null and then Clock.TM = null then

         Clock.TM := TM;

         TM.all := (Clock   => Clock,
                    Handler => Handler,
                    Data    => Data,
                    Timeout => CPU_Time'Last,
                    Set     => False);

         Success := True;

      else
         Success := False;
      end if;

   end Initialize_Timer;

   --------------------
   -- Initialize_TMU --
   --------------------

   procedure Initialize_TMU (Environment_Thread : Thread_Id) is
   begin
      --  Initialize clock of environment and idle threads

      Initialize_Clock (Environment_Thread.Clock'Access);
      Initialize_Clock (Idle);

      --  Install compare handler

      Interrupts.Attach_Handler (Compare_Handler'Access, Peripherals.COMPARE);

      --  Activate clock of environment thread

      Stack (0) := Environment_Thread.Clock'Access;

      CPU.Reset_Count (Max_Compare);

   end Initialize_TMU;

   ---------------------
   -- Interrupt_Clock --
   ---------------------

   function Interrupt_Clock (Id : Interrupt_ID) return Clock_Id is
      I : constant Pool_Index := Lookup (Id);
   begin
      if I > 0 then
         return Pool (I)'Access;
      else
         return null;
      end if;
   end Interrupt_Clock;

   ----------------
   -- Leave_Idle --
   ----------------

   procedure Leave_Idle (Id : Thread_Id) is
      A : constant Clock_Id := Id.Active_Clock;
      B : constant Clock_Id := Id.Clock'Access;

   begin
      pragma Assert (Top = 0 and then A = Stack (0));
      pragma Assert (A = Idle);

      Swap_Clock (A, B);

      Id.Active_Clock := B;
      Stack (0) := B;

   end Leave_Idle;

   ---------------------
   -- Leave_Interrupt --
   ---------------------

   procedure Leave_Interrupt is
      A : constant Clock_Id := Stack (Top);
   begin
      pragma Assert (Top > 0);

      Stack (Top) := null;
      Top := Top - 1;

      Swap_Clock (A, Stack (Top));

   end Leave_Interrupt;

   ---------
   -- Set --
   ---------

   procedure Set
     (TM      : Timer_Id;
      Timeout : CPU_Time)
   is
   begin

      pragma Assert (TM /= null);

      --  Set timer and adjust COMPARE if its clock is active

      TM.Timeout := Timeout;

      if Active (TM.Clock) then
         CPU.Adjust_Compare (Get_Compare (TM.Clock));
      end if;

   end Set;

   ----------------
   -- Swap_Clock --
   ----------------

   procedure Swap_Clock (A, B : Clock_Id) is
      Count : Word;
   begin
      CPU.Swap_Count (Get_Compare (B), Count);
      A.Base_Time := A.Base_Time + CPU_Time (Count);
   end Swap_Clock;

   --------------------
   -- Time_Remaining --
   --------------------

   function Time_Remaining (TM : Timer_Id) return CPU_Time is
      Now, Timeout : CPU_Time;
   begin

      loop
         Timeout := TM.Timeout;
         Now     := Execution_Time (TM.Clock);
         exit when Timeout = TM.Timeout;
      end loop;

      if TM.Set and then Timeout > Now then
         return Timeout - Now;
      else
         return CPU_Time'First;
      end if;

   end Time_Remaining;

   ------------------
   -- Thread_Clock --
   ------------------

   function Thread_Clock (Id : Thread_Id) return Clock_Id is
   begin
      return Id.Clock'Access;
   end Thread_Clock;

end System.BB.TMU;
