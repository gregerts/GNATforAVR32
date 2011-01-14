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

   package SBP renames System.BB.Parameters;

   type Pool_Index is range 0 .. SBP.Interrupt_Timers;

   type Stack_Index is new Interrupts.Interrupt_Level;

   use type Peripherals.TMU_Interval;

   -----------------------
   -- Local definitions --
   -----------------------

   Timer_Pool : array (Pool_Index) of aliased Timer_Descriptor;
   --  Clocks used for interrupt handling

   Interrupt_TM : array (Interrupt_ID) of Timer_Id;
   --  Array for translating interrupt IDs to timers (in pool)

   Idle_TM : constant Timer_Id := Timer_Pool (0)'Access;
   --  Constant access to idle timer (first in pool)

   Stack : array (Stack_Index) of Timer_Id;
   --  Stack of timers

   Top : Stack_Index;
   --  Index of stack top

   -----------------------
   -- Local subprograms --
   -----------------------

   function Active (TM : Timer_Id) return Boolean;
   pragma Inline_Always (Active);
   --  Returns true when the given timer is active

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID);
   --  Handler for the TMU compare interrupt

   procedure Swap (A, B : Timer_Id);
   --  Swap active timer from A to B

   ------------
   -- Active --
   ------------

   function Active (TM : Timer_Id) return Boolean is
   begin
      return TM = Stack (Top);
   end Active;

   ----------
   -- Bind --
   ----------

   procedure Bind
     (TM      : Timer_Id;
      Handler : Timer_Handler;
      Data    : System.Address;
      Success : out Boolean)
   is
   begin

      pragma Assert (Handler /= null);

      if TM.Handler = null then
         TM.Handler := Handler;
         TM.Data := Data;
         Success := True;
      else
         Success := False;
      end if;

   end Bind;

   ------------
   -- Cancel --
   ------------

   procedure Cancel (TM : Timer_Id) is
   begin

      pragma Assert (TM /= null);

      if TM.State = Set then

         --  Clear timer and adjust COMPARE if its clock is active

         TM.Compare := CPU_Time'Last;
         TM.State := Cleared;

         if Active (TM) then
            Peripherals.Set_Compare (TM.Compare);
         end if;

      end if;

   end Cancel;

   -----------
   -- Clock --
   -----------

   function Clock (TM : Timer_Id) return CPU_Time is
   begin
      pragma Assert (TM /= null);

      --  If clock is not active return base time

      if Active (TM) then
         return Peripherals.Get_Count;
      else
         return TM.Count;
      end if;

   end Clock;

   ---------------------
   -- Compare_Handler --
   ---------------------

   procedure Compare_Handler (Id : Interrupts.Interrupt_ID) is

      --  Only the clock second from the top of the stack can have
      --  expired as timeouts are not allowed for highest priority.

      TM : constant Timer_Id := Stack (Top - 1);

   begin

      pragma Assert (Id = Peripherals.TMUC);

      --  Clear TM and call handler if it has expired

      if TM.Compare <= TM.Count then

         pragma Assert (TM.Handler /= null);

         TM.Compare := CPU_Time'Last;
         TM.State := Cleared;

         TM.Handler (TM.Data);

      end if;

   end Compare_Handler;

   ----------------
   -- Enter_Idle --
   ----------------

   procedure Enter_Idle (Id : Thread_Id) is
      A : constant Timer_Id := Id.Active_TM;
      B : constant Timer_Id := Idle_TM;

   begin
      pragma Assert (Top = 0 and then A = Stack (0));
      pragma Assert (A = Id.TM'Access);

      Id.Active_TM := B;
      Stack (0) := B;

      Swap (A, B);

   end Enter_Idle;

   ---------------------
   -- Enter_Interrupt --
   ---------------------

   procedure Enter_Interrupt (Id : Interrupt_ID) is
      A : constant Timer_Id := Stack (Top);
      B : constant Timer_Id := Interrupt_TM (Id);

   begin
      pragma Assert (Top < Stack'Last);
      pragma Assert (B /= null);

      --  Set new top of stack

      Top         := Top + 1;
      Stack (Top) := B;

      --  Swap timer to new top of stack

      Swap (A, B);

   end Enter_Interrupt;

   --------------------------------
   -- Initialize_Interrupt_Timer --
   --------------------------------

   procedure Initialize_Interrupt_Timer (Id : Interrupt_ID) is
      TM : Timer_Id := null;
   begin
      pragma Assert (Interrupt_TM (Id) = null);

      for I in 1 .. Pool_Index'Last loop
         if Timer_Pool (I).State = Uninitialized then
            TM := Timer_Pool (I)'Access;
            exit;
         end if;
      end loop;

      pragma Assert (TM /= null);

      Interrupt_TM (Id) := TM;

      if Interrupts.To_Priority (Id) < Interrupt_Priority'Last then
         TM.State := Free;
      else
         TM.State := Cleared;
      end if;

   end Initialize_Interrupt_Timer;

   -----------------------------
   -- Initialize_Thread_Timer --
   -----------------------------

   procedure Initialize_Thread_Timer (Id : Thread_Id) is
   begin
      pragma Assert (Id.TM.State = Uninitialized);

      Id.TM.State := Free;
      Id.Active_TM := Id.TM'Access;

   end Initialize_Thread_Timer;

   --------------------
   -- Initialize_TMU --
   --------------------

   procedure Initialize_TMU (Environment_Thread : Thread_Id) is
   begin
      --  Initialize the timer of the environment thread

      Initialize_Thread_Timer (Environment_Thread);

      --  Initialize idle task timer, no user timer allowed

      Idle_TM.State := Cleared;

      --  Install compare handler

      Interrupts.Attach_Handler (Compare_Handler'Access, Peripherals.COMPARE);

      --  Activate clock of environment thread

      Stack (0) := Environment_Thread.Active_TM;

      Peripherals.Set_Compare (CPU_Time'Last);

   end Initialize_TMU;

   ---------------------
   -- Interrupt_Timer --
   ---------------------

   function Interrupt_Timer (Id : Interrupt_ID) return Timer_Id is
   begin
      return Interrupt_TM (Id);
   end Interrupt_Timer;

   ----------------
   -- Leave_Idle --
   ----------------

   procedure Leave_Idle (Id : Thread_Id) is
      A : constant Timer_Id := Id.Active_TM;
      B : constant Timer_Id := Id.TM'Access;

   begin
      pragma Assert (Top = 0 and then A = Stack (0));
      pragma Assert (A = Idle_TM);

      Id.Active_TM := B;
      Stack (0) := B;

      Swap (A, B);

   end Leave_Idle;

   ---------------------
   -- Leave_Interrupt --
   ---------------------

   procedure Leave_Interrupt is
      TM : constant Timer_Id := Stack (Top);
   begin
      pragma Assert (Top > 0);

      --  Set new top of stack

      Stack (Top) := null;
      Top         := Top - 1;

      Swap (TM, Stack (Top));

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

      TM.Compare := Timeout;

      if Active (TM) then
         Peripherals.Set_Compare (TM.Compare);
      end if;

   end Set;

   ----------
   -- Swap --
   ----------

   procedure Swap (A, B : Timer_Id) is
   begin
      pragma Assert (A /= B);

      Peripherals.Swap_Context (B.Compare, B.Count, A.Count);
   end Swap;

   --------------------
   -- Time_Remaining --
   --------------------

   function Time_Remaining (TM : Timer_Id) return CPU_Time is
      Now, Timeout : CPU_Time;

   begin

      if TM.State = Set then

         loop
            Timeout := TM.Compare;
            Now     := Clock (TM);
            exit when Timeout = TM.Compare;
         end loop;

         return Timeout - Now;
      else
         return CPU_Time'First;
      end if;

   end Time_Remaining;

   ------------------
   -- Thread_Timer --
   ------------------

   function Thread_Timer (Id : Thread_Id) return Timer_Id is
   begin
      return Id.TM'Access;
   end Thread_Timer;

end System.BB.TMU;
