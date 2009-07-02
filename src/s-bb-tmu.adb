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

   type Interrupt_Clock_Array is
     array (Interrupt_Priority) of aliased Clock_Descriptor;
   pragma Suppress_Initialization (Interrupt_Clock_Array);

   subtype Clock_Index is Interrupts.Interrupt_Level;

   type Clock_Array is array (Clock_Index) of Clock_Id;
   pragma Suppress_Initialization (Clock_Array);

   -----------------------
   -- Local definitions --
   -----------------------

   Max_Compare : constant := Word'Last / 2;
   --  Maximal value set to COMPARE register

   Idle_Clock_Desc : aliased Clock_Descriptor;
   --  Clock of the pseudo idle thread

   Interrupt_Clock_Desc : Interrupt_Clock_Array;
   --  Clocks of the pseudo server threads for each interrupt priority

   Stack : Clock_Array;
   --  Stack of timers

   Top : Clock_Index;
   --  Index of stack top

   To_Clock : Clock_Array;
   --  Access to interrupt level clock indexed by level

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Change_Clock (Clock_A, Clock_B : Clock_Id);
   --  Change clock from Clk_A to Clk_B

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID);
   --  Handler for the COMPARE interrupt

   procedure Context_Switch (Running, First : Thread_Id);
   pragma Export (Asm, Context_Switch, "tmu_context_switch");
   --  Changes TMU context from the running to first thread

   function Get_Compare (Clock : Clock_Id) return Word;
   pragma Inline (Get_Compare);
   --  Computes the COMPARE value for a clock

   ------------
   -- Cancel --
   ------------

   procedure Cancel (TM : Timer_Id) is
   begin

      pragma Assert (TM /= null);

      if TM.Set then

         TM.Set := False;
         TM.Timeout := CPU_Time'First;

         if TM.Clock.Running then
            CPU.Adjust_Compare (Max_Compare);
         end if;

      end if;

   end Cancel;

   ------------------
   -- Change_Clock --
   ------------------

   procedure Change_Clock (Clock_A, Clock_B : Clock_Id) is
      Count : Word;
   begin

      pragma Assert (Clock_A.Running and not Clock_B.Running);

      --  TM_A is active, TM_B is being actived

      Clock_A.Running := False;
      Clock_B.Running := True;

      --  Swap in counter for TM_B

      CPU.Swap_Count (Get_Compare (Clock_B), Count);

      --  Update base time for TM_A

      Clock_A.Base_Time := Clock_A.Base_Time + CPU_Time (Count);

   end Change_Clock;

   ---------------------
   -- Compare_Handler --
   ---------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID) is
      Clock : Clock_Id;
      TM    : Timer_Id;
   begin

      pragma Assert (Id = Peripherals.COMPARE);
      pragma Assert (Top > 0);

      --  Only the active clock second from the top of the stack can
      --  have an expired timer since timeouts are not allowed for
      --  highest priority.

      Clock := Stack (Top - 1).Active;
      TM    := Clock.TM;

      --  Check if the timer is non-null, is set and has expired

      if TM /= null
        and then TM.Set
        and then TM.Timeout <= Clock.Base_Time then

         --  Clear timer and call handler

         pragma Assert (TM.Handler /= null);

         TM.Set := False;
         TM.Timeout := CPU_Time'First;
         TM.Handler (TM.Data);

      end if;

   end Compare_Handler;

   --------------------
   -- Context_Switch --
   --------------------

   procedure Context_Switch (Running, First : Thread_Id) is
   begin

      --  Set bottom of stack to timer of first thread

      Stack (0) := First.Clock'Access;

      --  Swap active timers if not in interrupt

      if Top = 0 then
         Change_Clock (Running.Clock.Active, First.Clock.Active);
      else
         Leave_Interrupt;
      end if;

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

      if Clock.TM = null
        and then Clock /= Interrupt_Clock (Interrupt_Priority'Last) then

         TM := new Timer_Descriptor (Clock);

         TM.Handler := Handler;
         TM.Data    := Data;
         TM.Timeout := CPU_Time'First;
         TM.Set     := False;

         Clock.TM := TM;

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

      Clock.Active := Idle_Clock_Desc'Access;

      Change_Clock (Clock, Clock.Active);

   end Enter_Idle;

   ---------------------
   -- Enter_Interrupt --
   ---------------------

   procedure Enter_Interrupt (Level : Interrupts.Interrupt_Level) is
      Clock_A : constant Clock_Id := Stack (Top).Active;
      Clock_B : constant Clock_Id := To_Clock (Level);

   begin

      pragma Assert (Level > 0);
      pragma Assert (Top < Stack'Last);

      --  Set new top of stack

      Top         := Top + 1;
      Stack (Top) := Clock_B;

      --  Swap timer to new top of stack

      Change_Clock (Clock_A, Clock_B);

   end Enter_Interrupt;

   -----------------
   -- Enter_Proxy --
   -----------------

   procedure Enter_Proxy (Id : Thread_Id) is
   begin

      CPU.Disable_Interrupts;

      declare
         Clock : constant Clock_Id := Stack (Top);
      begin
         pragma Assert (Clock.Active = Clock);

         Clock.Active := Id.Clock'Access;

         Change_Clock (Clock, Clock.Active);
      end;

      CPU.Restore_Interrupts;

   end Enter_Proxy;

   -----------------
   -- Get_Compare --
   -----------------

   function Get_Compare (Clock : Clock_Id) return Word is
      B : constant CPU_Time := Clock.Base_Time;
   begin

      if Clock.TM = null or else not Clock.TM.Set then
         return Max_Compare;
      elsif Clock.TM.Timeout > B then
         return Word (CPU_Time'Min (Clock.TM.Timeout - B, Max_Compare));
      else
         return 1;
      end if;

   end Get_Compare;

   ----------------
   -- Idle_Clock --
   ----------------

   function Idle_Clock return Clock_Id is
   begin
      return Idle_Clock_Desc'Access;
   end Idle_Clock;

   ----------------------
   -- Initialize_Clock --
   ----------------------

   procedure Initialize_Clock (Clock : Clock_Id) is
   begin
      Clock.Active := Clock;
   end Initialize_Clock;

   --------------------
   -- Initialize_TMU --
   --------------------

   procedure Initialize_TMU (Environment_Clock : Clock_Id) is
      Clock : Clock_Id;
   begin
      --  Initialize the clock of the environment thread

      Initialize_Clock (Environment_Clock);

      --  Initialize pseudo thread clock

      Initialize_Clock (Idle_Clock_Desc'Access);

      for I in Interrupt_Clock_Desc'Range loop
         Clock := Interrupt_Clock_Desc (I)'Access;
         Initialize_Clock (Clock);
         To_Clock (I - Interrupt_Clock_Desc'First + 1) := Clock;
      end loop;

      --  Install compare handler

      Interrupts.Attach_Handler (Compare_Handler'Access, Peripherals.COMPARE);

      --  Activate clock of environment thread

      Stack (0) := Environment_Clock;
      Environment_Clock.Running := True;

      CPU.Reset_Count (Max_Compare);

   end Initialize_TMU;

   ---------------------
   -- Interrupt_Clock --
   ---------------------

   function Interrupt_Clock
     (Priority : Interrupt_Priority) return Clock_Id
   is
   begin
      return Interrupt_Clock_Desc (Priority)'Access;
   end Interrupt_Clock;

   ----------------
   -- Leave_Idle --
   ----------------

   procedure Leave_Idle is
      Clock : constant Clock_Id := Stack (0);
   begin
      pragma Assert (Top = 0);
      pragma Assert (Clock.Active = Idle_Clock_Desc'Access);

      Change_Clock (Clock.Active, Clock);

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

      Change_Clock (Clock, Stack (Top).Active);

   end Leave_Interrupt;

   -----------------
   -- Leave_Proxy --
   -----------------

   procedure Leave_Proxy is
   begin

      CPU.Disable_Interrupts;

      declare
         Clock : constant Clock_Id := Stack (Top);
      begin
         pragma Assert (Clock.Active /= Clock);

         Change_Clock (Clock.Active, Clock);

         Clock.Active := Clock;
      end;

      CPU.Restore_Interrupts;

   end Leave_Proxy;

   ---------
   -- Set --
   ---------

   procedure Set
     (TM      : Timer_Id;
      Timeout : CPU_Time)
   is
   begin
      pragma Assert (TM.Clock /= null);

      --  Set timer

      TM.Set := True;
      TM.Timeout := Timeout;

      --  Adjust COMPARE if the timer is active

      if TM.Clock.Running then
         CPU.Adjust_Compare (Get_Compare (TM.Clock));
      end if;

   end Set;

   -------------
   -- Time_Of --
   -------------

   function Time_Of (Clock : Clock_Id) return CPU_Time is
      B : CPU_Time;
      C : Word;

   begin
      pragma Assert (Clock /= null);

      --  If clock is not active return base time

      if not Clock.Running then
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
