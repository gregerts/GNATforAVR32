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

   type Interrupt_Clock_Index is range 0 .. SBP.Interrupt_Clocks;
   for Interrupt_Clock_Index'Size use 8;

   type Interrupt_Clock_Array is array (Interrupt_Clock_Index)
     of aliased Clock_Descriptor;

   pragma Suppress_Initialization (Interrupt_Clock_Array);

   type Clock_Index is new Interrupts.Interrupt_Level;

   type Clock_Stack is array (Clock_Index) of Clock_Id;

   pragma Suppress_Initialization (Clock_Stack);

   -----------------------
   -- Local definitions --
   -----------------------

   Max_Compare : constant := Word'Last / 2;
   --  Maximal value set to COMPARE register

   Idle_Clock : aliased Clock_Descriptor;
   --  Clock of the pseudo idle thread

   Interrupt_Clocks : Interrupt_Clock_Array;
   --  Clocks used for interrupt handling

   Last_Interrupt_Clock : Interrupt_Clock_Index := 0;
   --  Pointing to last allocated interrupt clock

   To_Clock_Index : array (Interrupt_ID) of Interrupt_Clock_Index;
   --  Array for translating interrupt IDs to interrupt clock index

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

   procedure Initialize_Clock (Clock : Clock_Id);
   --  Initializes the given clock

   function Is_Active (Clock : Clock_Id) return Boolean;
   pragma Inline_Always (Is_Active);
   --  Returns true when the given clock is active (running)

   procedure Swap_Clock (A, B : Clock_Id);
   --  Swap clock from A to B

   ------------
   -- Cancel --
   ------------

   procedure Cancel (TM : Timer_Id) is
   begin

      pragma Assert (TM /= null);

      if TM.Set then

         --  Clear timer and adjust COMPARE if its clock is active

         TM.Timeout := CPU_Time'First;
         TM.Set := False;

         if Is_Active (TM.Clock) then
            CPU.Adjust_Compare (Max_Compare);
         end if;

      end if;

   end Cancel;

   --------------
   -- Clock_Of --
   --------------

   function Clock_Of (TM : Timer_Id) return Clock_Id is
   begin
      return TM.Clock;
   end Clock_Of;

   ---------------------
   -- Compare_Handler --
   ---------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID) is

      --  Only the clock second from the top of the stack can have
      --  expired as timeouts are not allowed for highest priority.

      Clock : constant Clock_Id := Stack (Top - 1);
      TM    : constant Timer_Id := Clock.TM'Access;

   begin

      pragma Assert (Id = Peripherals.COMPARE);

      --  Clear TM and call handler if it has expired

      if TM.Set and then TM.Timeout <= Clock.Base_Time then

         pragma Assert (TM.Handler /= null);

         TM.Timeout := CPU_Time'First;
         TM.Set := False;

         TM.Handler (TM.Data);

      end if;

   end Compare_Handler;

   --------------------
   -- Context_Switch --
   --------------------

   procedure Context_Switch (Running, First : Thread_Id) is
   begin

      --  Set bottom of stack to timer of first thread and swap to the
      --  timer of this thread.

      Stack (0) := First.Active_Clock;

      Swap_Clock (Running.Active_Clock, First.Active_Clock);

   end Context_Switch;

   ------------
   -- Create --
   ------------

   function Create
     (Clock   : Clock_Id;
      Handler : not null Timer_Handler;
      Data    : System.Address) return Timer_Id
   is
      TM : Timer_Id := null;
   begin

      if Clock.TM.Free then

         TM := Clock.TM'Access;

         TM.Handler := Handler;
         TM.Data    := Data;

      end if;

      return TM;

   end Create;

   ----------------
   -- Enter_Idle --
   ----------------

   procedure Enter_Idle (Id : Thread_Id) is
      A : constant Clock_Id := Id.Active_Clock;
      B : constant Clock_Id := Idle_Clock'Access;

   begin
      pragma Assert (Top = 0 and then A = Stack (0));
      pragma Assert (A = Id.Clock'Access);

      Id.Active_Clock := B;
      Stack (0) := B;

      Swap_Clock (A, B);

   end Enter_Idle;

   ---------------------
   -- Enter_Interrupt --
   ---------------------

   procedure Enter_Interrupt (Id : Interrupt_ID) is
      A : constant Clock_Id := Stack (Top);
      B : constant Clock_Id := Interrupt_Clock (Id);

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
      T  : constant CPU_Time := Clock.Base_Time;
      TM : constant Timer_Id := Clock.TM'Access;
   begin

      if not TM.Set then
         return Max_Compare;
      elsif TM.Timeout > T then
         return Word (CPU_Time'Min (TM.Timeout - T, Max_Compare));
      else
         return 1;
      end if;

   end Get_Compare;

   ----------------------
   -- Initialize_Clock --
   ----------------------

   procedure Initialize_Clock (Clock : Clock_Id) is
   begin
      Clock.TM.Clock := Clock;
      Clock.TM.Free  := True;
   end Initialize_Clock;

   --------------------------------
   -- Initialize_Interrupt_Clock --
   --------------------------------

   procedure Initialize_Interrupt_Clock (Id : Interrupt_ID) is
   begin
      pragma Assert (To_Clock_Index (Id) = 0);
      pragma Assert (Last_Interrupt_Clock < Interrupt_Clock_Index'Last);

      Last_Interrupt_Clock := Last_Interrupt_Clock + 1;

      To_Clock_Index (Id) := Last_Interrupt_Clock;

      if Interrupts.To_Priority (Id) = Interrupt_Priority'Last then
         Interrupt_Clocks (Last_Interrupt_Clock).TM.Free := False;
      end if;

   end Initialize_Interrupt_Clock;

   -----------------------------
   -- Initialize_Thread_Clock --
   -----------------------------

   procedure Initialize_Thread_Clock (Id : Thread_Id) is
   begin
      Id.Active_Clock := Id.Clock'Access;
      Initialize_Clock (Id.Active_Clock);
   end Initialize_Thread_Clock;

   --------------------
   -- Initialize_TMU --
   --------------------

   procedure Initialize_TMU (Environment_Thread : Thread_Id) is
   begin
      --  Initialize the clock of the environment thread

      Initialize_Clock (Environment_Thread.Clock'Access);

      --  Initialize idle task clock, no timers allowed

      Initialize_Clock (Idle_Clock'Access);

      --  Initialize interrupt clocks

      for I in Interrupt_Clocks'Range loop
         Initialize_Clock (Interrupt_Clocks (I)'Access);
      end loop;

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
   begin
      return Interrupt_Clocks (To_Clock_Index (Id))'Access;
   end Interrupt_Clock;

   ---------------
   -- Is_Active --
   ---------------

   function Is_Active (Clock : Clock_Id) return Boolean is
   begin
      return Clock = Stack (Top);
   end Is_Active;

   ----------------
   -- Leave_Idle --
   ----------------

   procedure Leave_Idle (Id : Thread_Id) is
      A : constant Clock_Id := Id.Active_Clock;
      B : constant Clock_Id := Id.Clock'Access;

   begin
      pragma Assert (Top = 0 and then A = Stack (0));
      pragma Assert (A = Idle_Clock'Access);

      Id.Active_Clock := B;
      Stack (0) := B;

      Swap_Clock (A, B);

   end Leave_Idle;

   ---------------------
   -- Leave_Interrupt --
   ---------------------

   procedure Leave_Interrupt is
      Clock : constant Clock_Id := Stack (Top);
   begin
      pragma Assert (Top > 0);

      --  Set new top of stack

      Stack (Top) := null;
      Top         := Top - 1;

      Swap_Clock (Clock, Stack (Top));

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

      if Is_Active (TM.Clock) then
         CPU.Adjust_Compare (Get_Compare (TM.Clock));
      end if;

   end Set;

   ----------------
   -- Swap_Clock --
   ----------------

   procedure Swap_Clock (A, B : Clock_Id) is
      Count : Word;
   begin
      pragma Assert (A /= B);

      --  Swap in counter for B

      CPU.Swap_Count (Get_Compare (B), Count);

      --  Update base time for A

      A.Base_Time := A.Base_Time + CPU_Time (Count);

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
