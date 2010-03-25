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

   type Interrupt_Timer_Array is array (Interrupt_Priority)
     of aliased Timer_Descriptor;

   pragma Suppress_Initialization (Interrupt_Timer_Array);

   subtype Timer_Index is Interrupts.Interrupt_Level;

   type Timer_Array is array (Timer_Index) of Timer_Id;
   pragma Suppress_Initialization (Timer_Array);

   -----------------------
   -- Local definitions --
   -----------------------

   Max_Compare : constant := Word'Last / 2;
   --  Maximal value set to COMPARE register

   Idle_TM : aliased Timer_Descriptor;
   --  Timer of the pseudo idle thread

   Interrupt_TM : Interrupt_Timer_Array;
   --  Timers of the pseudo server threads for each interrupt priority

   Stack : Timer_Array;
   --  Stack of timers

   Top : Timer_Index;
   --  Index of stack top

   To_Timer : Timer_Array;
   --  Access to interrupt level timers indexed by level

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID);
   --  Handler for the COMPARE interrupt

   procedure Context_Switch (Running, First : Thread_Id);
   pragma Export (Asm, Context_Switch, "tmu_context_switch");
   --  Changes TMU context from the running to first thread. This
   --  procedure is only called from context switch assembler code.

   function Get_Compare (TM : Timer_Id) return Word;
   pragma Inline (Get_Compare);
   --  Computes the COMPARE value for a timer from its status, base
   --  time and timeout. The returned value is always in the range
   --  from 1 to Max_Compare.

   procedure Swap_Timer (TM_A, TM_B : Timer_Id);
   --  Swap timer from TM_A to TM_B

   ----------------------------
   -- Aquire_Interrupt_Timer --
   ----------------------------

   procedure Acquire_Interrupt_Timer
     (Priority : Interrupt_Priority;
      Handler  : Timer_Handler;
      Data     : System.Address;
      TM       : out Timer_Id)
   is
   begin
      pragma Assert (Handler /= null);

      --  Timer for the highest interrupt level is not supported

      if Priority < Interrupt_Priority'Last
        and then Interrupt_TM (Priority).Handler = null then
         TM := Interrupt_TM (Priority)'Access;
         TM.Handler := Handler;
         TM.Data := Data;
      else
         TM := null;
      end if;

   end Acquire_Interrupt_Timer;

   --------------------------
   -- Acquire_Thread_Timer --
   --------------------------

   procedure Acquire_Thread_Timer
     (Id      : Thread_Id;
      Handler : Timer_Handler;
      Data    : System.Address;
      TM      : out Timer_Id)
   is
   begin
      pragma Assert (Handler /= null);

      if Id.TM.Handler = null then
         TM := Id.TM'Access;
         TM.Handler := Handler;
         TM.Data := Data;
      else
         TM := null;
      end if;

   end Acquire_Thread_Timer;

   --------------------
   -- Cancel_Handler --
   --------------------

   procedure Cancel_Handler (TM : Timer_Id) is
   begin

      pragma Assert (TM /= null);

      if TM.Set then

         TM.Timeout := CPU_Time'First;

         if TM.Active then
            CPU.Adjust_Compare (Max_Compare);
         end if;

      end if;

   end Cancel_Handler;

   -----------
   -- Clock --
   -----------

   function Clock (TM : Timer_Id) return CPU_Time is
      B : CPU_Time;
      C : Word;

   begin

      pragma Assert (TM /= null);

      --  If TM is not active return base time

      if not TM.Active then
         return TM.Base_Time;
      end if;

      --  Else Clock is sum of base time and count

      loop

         B := TM.Base_Time;
         C := CPU.Get_Count;

         exit when B = TM.Base_Time;

      end loop;

      return B + CPU_Time (C);

   end Clock;

   ---------------------
   -- Compare_Handler --
   ---------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID) is
      TM : Timer_Id;
   begin

      pragma Assert (Id = Peripherals.COMPARE);
      pragma Assert (Top > 0);

      --  Only the active timer second from the top of the stack can
      --  be expired since timeouts are not allowed for highest
      --  priority.

      TM := Stack (Top - 1).Active_TM;

      --  Check if the timer is set and has expired

      if TM.Set and then TM.Timeout <= TM.Base_Time then

         TM.Timeout := CPU_Time'First;
         TM.Set     := False;

         TM.Handler (TM.Data);

      end if;

   end Compare_Handler;

   --------------------
   -- Context_Switch --
   --------------------

   procedure Context_Switch (Running, First : Thread_Id) is
   begin

      --  Set bottom of stack to timer of first thread

      Stack (0) := First.TM'Access;

      --  Swap active timers if not in interrupt

      if Top = 0 then
         Swap_Timer (Running.TM.Active_TM, First.TM.Active_TM);
      else
         Leave_Interrupt;
      end if;

   end Context_Switch;

   ----------------
   -- Enter_Idle --
   ----------------

   procedure Enter_Idle is
      TM : constant Timer_Id := Stack (0);
   begin
      pragma Assert (Top = 0);
      pragma Assert (TM.Active_TM = TM);

      TM.Active_TM := Idle_TM'Access;

      Swap_Timer (TM, TM.Active_TM);

   end Enter_Idle;

   ---------------------
   -- Enter_Interrupt --
   ---------------------

   procedure Enter_Interrupt (Level : Interrupts.Interrupt_Level) is
      TM_A : constant Timer_Id := Stack (Top).Active_TM;
      TM_B : constant Timer_Id := To_Timer (Level);

   begin

      pragma Assert (Level > 0);
      pragma Assert (Top < Stack'Last);

      --  Set new top of stack

      Top         := Top + 1;
      Stack (Top) := TM_B;

      --  Swap timer to new top of stack

      Swap_Timer (TM_A, TM_B);

   end Enter_Interrupt;

   -----------------
   -- Enter_Proxy --
   -----------------

   procedure Enter_Proxy (Id : Thread_Id) is
   begin

      CPU.Disable_Interrupts;

      declare
         TM : constant Timer_Id := Stack (Top);
      begin
         pragma Assert (TM.Active_TM = TM);

         TM.Active_TM := Id.TM'Access;

         Swap_Timer (TM, TM.Active_TM);
      end;

      CPU.Restore_Interrupts;

   end Enter_Proxy;

   -----------------
   -- Get_Compare --
   -----------------

   function Get_Compare (TM : Timer_Id) return Word is
      B : constant CPU_Time := TM.Base_Time;
   begin

      if not TM.Set then
         return Max_Compare;
      elsif TM.Timeout > B then
         return Word (CPU_Time'Min (TM.Timeout - B, Max_Compare));
      else
         return 1;
      end if;

   end Get_Compare;

   ----------------------
   -- Initialize_Timer --
   ----------------------

   procedure Initialize_Timer (TM : Timer_Id) is
   begin
      TM.Active_TM := TM;
   end Initialize_Timer;

   --------------------
   -- Initialize_TMU --
   --------------------

   procedure Initialize_TMU (Environment_TM : Timer_Id) is
   begin
      --  Initialize environment thread timer

      Initialize_Timer (Environment_TM);

      --  Initialize pseudo thread timers

      Initialize_Timer (Idle_TM'Access);

      for I in Interrupt_TM'Range loop
         declare
            TM : constant Timer_Id := Interrupt_TM (I)'Access;
         begin
            Initialize_Timer (TM);
            To_Timer (I - Interrupt_TM'First + 1) := TM;
         end;
      end loop;

      --  Install compare handler

      Interrupts.Attach_Handler (Compare_Handler'Access, Peripherals.COMPARE);

      --  Activate environment thread timer

      Stack (0) := Environment_TM;

      Environment_TM.Active := True;

      CPU.Reset_Count (Max_Compare);

   end Initialize_TMU;

   ---------------------
   -- Interrupt_Clock --
   ---------------------

   function Interrupt_Clock
     (Priority : Interrupt_Priority) return CPU_Time
   is
   begin
      return Clock (Interrupt_TM (Priority)'Access);
   end Interrupt_Clock;

   ----------------
   -- Leave_Idle --
   ----------------

   procedure Leave_Idle is
      TM : constant Timer_Id := Stack (0);
   begin
      pragma Assert (Top = 0);
      pragma Assert (TM.Active_TM = Idle_TM'Access);

      Swap_Timer (TM.Active_TM, TM);

      TM.Active_TM := TM;

   end Leave_Idle;

   ---------------------
   -- Leave_Interrupt --
   ---------------------

   procedure Leave_Interrupt is
      TM : constant Timer_Id := Stack (Top);
   begin
      pragma Assert (Top > 0);
      pragma Assert (TM.Active_TM = TM);

      --  Set new top of stack

      Stack (Top) := null;
      Top         := Top - 1;

      Swap_Timer (TM, Stack (Top).Active_TM);

   end Leave_Interrupt;

   -----------------
   -- Leave_Proxy --
   -----------------

   procedure Leave_Proxy is
   begin

      CPU.Disable_Interrupts;

      declare
         TM : constant Timer_Id := Stack (Top);
      begin
         pragma Assert (TM.Active_TM /= TM);

         Swap_Timer (TM.Active_TM, TM);

         TM.Active_TM := TM;
      end;

      CPU.Restore_Interrupts;

   end Leave_Proxy;

   -----------------
   -- Set_Handler --
   -----------------

   procedure Set_Handler
     (TM      : Timer_Id;
      Timeout : CPU_Time)
   is
   begin
      pragma Assert (TM /= null);
      pragma Assert (TM.Handler /= null);

      --  Set handler

      TM.Timeout := Timeout;
      TM.Set := True;

      --  Adjust COMPARE if the timer is active

      if TM.Active then
         CPU.Adjust_Compare (Get_Compare (TM));
      end if;

   end Set_Handler;

   ----------------
   -- Swap_Timer --
   ----------------

   procedure Swap_Timer (TM_A, TM_B : Timer_Id) is
      Count : Word;
   begin

      pragma Assert (TM_A.Active and not TM_B.Active);

      --  TM_A is active, TM_B is being actived

      TM_A.Active := False;
      TM_B.Active := True;

      --  Swap in counter for TM_B

      CPU.Swap_Count (Get_Compare (TM_B), Count);

      --  Update base time for TM_A

      TM_A.Base_Time := TM_A.Base_Time + CPU_Time (Count);

   end Swap_Timer;

   --------------------
   -- Time_Remaining --
   --------------------

   function Time_Remaining (TM : Timer_Id) return CPU_Time is
      Now, Timeout : CPU_Time;
   begin

      --  Clock and timeout has to be consistent

      loop

         Timeout := TM.Timeout;
         Now     := Clock (TM);

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

   function Thread_Clock (Id : Thread_Id) return CPU_Time is
   begin
      return Clock (Id.TM'Access);
   end Thread_Clock;

end System.BB.TMU;
