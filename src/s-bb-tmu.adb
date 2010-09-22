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
with System.BB.Threads;

package body System.BB.TMU is

   package CPU renames System.BB.CPU_Primitives;

   use type CPU.Word;

   subtype Word is CPU.Word;

   type Interrupt_Clock_Array is array (Interrupt_ID) of Clock_Id;
   pragma Suppress_Initialization (Interrupt_Clock_Array);

   type Clock_Index is new Interrupts.Interrupt_Level;

   type Clock_Stack is array (Clock_Index) of Clock_Id;
   pragma Suppress_Initialization (Clock_Stack);

   -----------------------
   -- Local definitions --
   -----------------------

   Max_Compare : constant := Word'Last / 2;
   --  Maximal value set to COMPARE register

   Max_Timers : constant := 1;
   --  Maxmal number of timers allowed for a clock

   Idle_Clock : aliased Clock_Descriptor;
   --  Clock of the pseudo idle thread

   Interrupt_Clocks : Interrupt_Clock_Array;
   --  Clocks of the pseudo server threads for each interrupt priority

   Stack : Clock_Stack;
   --  Stack of timers

   Top : Clock_Index;
   --  Index of stack top

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID);
   --  Handler for the COMPARE interrupt

   procedure Context_Switch (Running, First : Thread_Id);
   pragma Export (Asm, Context_Switch, "tmu_context_switch");
   --  Changes TMU context from the running to first thread

   function Get_Compare (Clock : Clock_Id) return Word;
   pragma Inline (Get_Compare);
   --  Computes the COMPARE value for a clock

   function Is_Active (Clock : Clock_Id) return Boolean;
   pragma Inline_Always (Is_Active);
   --  Returns true when the given clock is active (running)

   function Is_Set (TM : Timer_Id) return Boolean;
   pragma Inline_Always (Is_Set);
   --  Returns true when the given timer is set

   procedure Swap_Clock (Clock_A, Clock_B : Clock_Id);
   --  Swap clock from Clk_A to Clk_B

   ------------
   -- Cancel --
   ------------

   procedure Cancel (TM : Timer_Id) is
   begin

      pragma Assert (TM /= null);

      if Is_Set (TM) then

         --  Clear timer and adjust COMPARE if its clock is active

         TM.Timeout := CPU_Time'First;
         TM.Clock.First_TM := null;

         if Is_Active (TM.Clock) then
            CPU.Adjust_Compare (Max_Compare);
         end if;

      end if;

   end Cancel;

   ---------------------
   -- Compare_Handler --
   ---------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID) is

      --  Only the active clock second from the top of the stack can
      --  have an expired timer since timeouts are not allowed for
      --  highest priority.

      Clock : constant Clock_Id := Stack (Top - 1).Active;
      TM    : constant Timer_Id := Clock.First_TM;

   begin

      pragma Assert (Id = Peripherals.COMPARE);

      --  Clear TM and call handler if it is non-null and has expired

      if TM /= null and then TM.Timeout <= Clock.Base_Time then

         pragma Assert (TM.Clock = Clock);
         pragma Assert (TM.Handler /= null);

         TM.Timeout := CPU_Time'First;
         TM.Clock.First_TM := null;

         TM.Handler (TM.Data);

      end if;

   end Compare_Handler;

   --------------------
   -- Context_Switch --
   --------------------

   procedure Context_Switch (Running, First : Thread_Id) is
   begin

      --  Set bottom of stack to timer of first thread and swap to the
      --  active timer of this thread.

      Stack (0) := First.Clock'Access;

      Swap_Clock (Running.Clock.Active, First.Clock.Active);

   end Context_Switch;

   ------------
   -- Create --
   ------------

   function Create
     (Clock   : not null Clock_Id;
      Handler : not null Timer_Handler;
      Data    : System.Address) return Timer_Id
   is
      TM : Timer_Id := null;
   begin

      if Clock.Free > 0 then

         Clock.Free := Clock.Free - 1;

         TM := new Timer_Descriptor (Clock);

         TM.Handler := Handler;
         TM.Data    := Data;
         TM.Timeout := CPU_Time'First;

      end if;

      return TM;

   end Create;

   ----------------
   -- Enter_Idle --
   ----------------

   procedure Enter_Idle is
      Clock : constant Clock_Id := Stack (0);
   begin
      pragma Assert (Top = 0);
      pragma Assert (Clock.Active = Clock);

      Clock.Active := Idle_Clock'Access;

      Swap_Clock (Clock, Clock.Active);

   end Enter_Idle;

   ---------------------
   -- Enter_Interrupt --
   ---------------------

   procedure Enter_Interrupt (Id : Interrupt_ID) is
      A : constant Clock_Id := Stack (Top).Active;
      B : constant Clock_Id := Interrupt_Clocks (Id);

   begin
      pragma Assert (Top < Stack'Last);
      pragma Assert (B /= null);

      --  Set new top of stack

      Top         := Top + 1;
      Stack (Top) := B;

      --  Swap timer to new top of stack

      Swap_Clock (A, B);

   end Enter_Interrupt;

   -----------------
   -- Get_Compare --
   -----------------

   function Get_Compare (Clock : Clock_Id) return Word is
      B  : constant CPU_Time := Clock.Base_Time;
      TM : constant Timer_Id := Clock.First_TM;
   begin

      if TM = null then
         return Max_Compare;
      elsif TM.Timeout > B then
         return Word (CPU_Time'Min (TM.Timeout - B, Max_Compare));
      else
         return 1;
      end if;

   end Get_Compare;

   ----------------------
   -- Initialize_Clock --
   ----------------------

   procedure Initialize_Clock (Clock : Clock_Id) is
   begin
      Clock.Base_Time := 0;
      Clock.Active    := Clock;
      Clock.Free      := Max_Timers;
   end Initialize_Clock;

   --------------------------
   -- Initialize_Interrupt --
   --------------------------

   procedure Initialize_Interrupt (Id : Interrupt_ID) is
   begin
      pragma Assert (Interrupt_Clocks (Id) = null);
      Interrupt_Clocks (Id) := new Clock_Descriptor;
      Initialize_Clock (Interrupt_Clocks (Id));
   end Initialize_Interrupt;

   --------------------
   -- Initialize_TMU --
   --------------------

   procedure Initialize_TMU (Environment_Clock : Clock_Id) is
   begin
      --  Initialize the clock of the environment thread

      Initialize_Clock (Environment_Clock);

      --  Initialize idle task clock, no timers allowed

      Initialize_Clock (Idle_Clock'Access);
      Idle_Clock.Free := 0;

      --  Install compare handler

      Interrupts.Attach_Handler (Compare_Handler'Access, Peripherals.COMPARE);

      --  Activate clock of environment thread

      Stack (0) := Environment_Clock;

      CPU.Reset_Count (Max_Compare);

   end Initialize_TMU;

   ---------------------
   -- Interrupt_Clock --
   ---------------------

   function Interrupt_Clock (Id : Interrupt_ID) return Clock_Id is
   begin
      return Interrupt_Clocks (Id);
   end Interrupt_Clock;

   ---------------
   -- Is_Active --
   ---------------

   function Is_Active (Clock : Clock_Id) return Boolean is
   begin
      return Clock = Stack (Top).Active;
   end Is_Active;

   ------------
   -- Is_Set --
   ------------

   function Is_Set (TM : Timer_Id) return Boolean is
   begin
      return TM = TM.Clock.First_TM;
   end Is_Set;

   ----------------
   -- Leave_Idle --
   ----------------

   procedure Leave_Idle is
      Clock : constant Clock_Id := Stack (0);
   begin
      pragma Assert (Top = 0);
      pragma Assert (Clock.Active = Idle_Clock'Access);

      Swap_Clock (Clock.Active, Clock);

      Clock.Active := Clock;

   end Leave_Idle;

   ---------------------
   -- Leave_Interrupt --
   ---------------------

   procedure Leave_Interrupt is
      Clock : constant Clock_Id := Stack (Top);
   begin
      pragma Assert (Top > 0);
      pragma Assert (Clock.Active = Clock);

      --  Set new top of stack

      Stack (Top) := null;
      Top         := Top - 1;

      Swap_Clock (Clock, Stack (Top).Active);

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
      TM.Clock.First_TM := TM;

      if Is_Active (TM.Clock) then
         CPU.Adjust_Compare (Get_Compare (TM.Clock));
      end if;

   end Set;

   ----------------
   -- Swap_Clock --
   ----------------

   procedure Swap_Clock (Clock_A, Clock_B : Clock_Id) is
      Count : Word;
   begin
      pragma Assert (Clock_A /= Clock_B);

      --  Swap in counter for TM_B

      CPU.Swap_Count (Get_Compare (Clock_B), Count);

      --  Update base time for TM_A

      Clock_A.Base_Time := Clock_A.Base_Time + CPU_Time (Count);

   end Swap_Clock;

   -------------
   -- Time_Of --
   -------------

   function Time_Of (Clock : Clock_Id) return CPU_Time is
      B : CPU_Time;
      C : Word;

   begin
      pragma Assert (Clock /= null);

      --  If clock is not active return base time

      if not Is_Active (Clock) then
         return Clock.Base_Time;
      end if;

      --  Else the time of clock is sum of base time and count

      loop
         B := Clock.Base_Time;
         C := CPU.Get_Count;
         exit when B = Clock.Base_Time;
      end loop;

      return B + CPU_Time (C);

   end Time_Of;

   --------------------
   -- Time_Remaining --
   --------------------

   function Time_Remaining (TM : Timer_Id) return CPU_Time is
      Now, Timeout : CPU_Time;
   begin

      --  Read timeout and clock

      loop
         Timeout := TM.Timeout;
         Now     := Time_Of (TM.Clock);
         exit when Timeout = TM.Timeout;
      end loop;

      --  TM.Timeout is CPU_Time'First when TM is not set

      if Timeout > Now then
         return Timeout - Now;
      else
         return 0;
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
