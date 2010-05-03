------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                          S Y S T E M . B B . T M U                       --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--             Copyright (C) 2007-2008 Kristoffer N. Gregertsen             --
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

pragma Restrictions (No_Elaboration_Code);

with System.BB.Interrupts;
with System.BB.Peripherals;

limited with System.BB.Threads;

package System.BB.TMU is

   pragma Preelaborate;

   --------------
   -- CPU_Time --
   --------------

   type CPU_Time is mod 2 ** 64;
   for CPU_Time'Size use 64;
   --  Type representing of CPU time

   CPU_Tick : constant := 1;
   --  Smallest amount of execution time representable by the CPU_Time

   CPU_Ticks_Per_Second : constant := Peripherals.Main_Clock_Frequency;
   --  Number of CPU ticks per second

   ---------------
   -- Thread_Id --
   ---------------

   type Thread_Id is not null access all System.BB.Threads.Thread_Descriptor;

   -----------------------
   -- Timer_Descriptor  --
   -----------------------

   type Timer_Descriptor is private;

   type Timer_Id is access all Timer_Descriptor;

   type Timer_Handler is access procedure (Data : System.Address);

   --------------------
   -- Initialization --
   --------------------

   procedure Initialize_Timer (TM : Timer_Id);
   --  Initializes the given timer.

   procedure Initialize_TMU (Environment_TM : Timer_Id);
   --  Initialize this package. Must be called before any other
   --  procedures and functions.

   ----------------
   -- Operations --
   ----------------

   procedure Acquire_Interrupt_Timer
     (Priority : Interrupt_Priority;
      Handler  : Timer_Handler;
      Data     : System.Address;
      TM       : out Timer_Id);
   --  Initialize timer of the given interrupt priority, returns null
   --  if the timer is already acquired.

   procedure Acquire_Thread_Timer
     (Id      : Thread_Id;
      Handler : Timer_Handler;
      Data    : System.Address;
      TM      : out Timer_Id);
   --  Initialize timer of the given thread, returns null if the timer
   --  is already acquired.

   procedure Cancel_Handler (TM : Timer_Id);
   --  Cancels handler of TM

   function Clock (TM : Timer_Id) return CPU_Time;
   --  Get execution time of the given timer

   function Interrupt_Clock
     (Priority : Interrupt_Priority) return CPU_Time;
   pragma Inline (Interrupt_Clock);
   --  Returns the execution time used by the pseudo interrupt level
   --  server thread.

   procedure Set_Handler
     (TM      : Timer_Id;
      Timeout : CPU_Time);
   --  Sets the timer, may overwrite an already pending timeout

   function Thread_Clock (Id : Thread_Id) return CPU_Time;
   pragma Inline (Thread_Clock);
   --  Returns execution time of the given thread

   function Time_Remaining (TM : Timer_Id) return CPU_Time;
   --  Returns time remaining before timeout or 0 if no timeout

   -------------------------
   -- Internal operations --
   -------------------------

   procedure Enter_Idle;
   pragma Inline (Enter_Idle);
   --  Enter idle mode

   procedure Enter_Interrupt (Level : Interrupts.Interrupt_Level);
   pragma Inline (Enter_Interrupt);
   --  Enter interrupt mode

   procedure Enter_Proxy (Id : Thread_Id);
   pragma Inline (Enter_Proxy);
   --  Enter proxy mode for the given thread

   procedure Leave_Idle;
   pragma Inline (Leave_Idle);
   --  Leave idle mode

   procedure Leave_Interrupt;
   pragma Inline (Leave_Interrupt);
   --  Leave interrupt mode

   procedure Leave_Proxy;
   pragma Inline (Leave_Proxy);
   --  Leave proxy mode

private

   type Timer_Descriptor is
      record
         Active_TM : Timer_Id;
         --  Will point to timer of another thread if this thread is
         --  executing code by proxy, otherwise to this timer.

         Base_Time : CPU_Time;
         pragma Volatile (Base_Time);
         --  Base time, updated when the timer is deactivated

         Timeout : CPU_Time;
         --  Timeout of timer or CPU_Time'First if timer is not set

         Handler : Timer_Handler;
         --  Handler to be called when the timer expires or null if
         --  timer not set.

         Data : System.Address;
         --  Argument to be given when calling handler

         Acquired, Active, Set : Boolean;
         --  Flags indicating if the timer is acquired, active
         --  (running) and set, respectivly.

      end record;

   pragma Suppress_Initialization (Timer_Descriptor);

end System.BB.TMU;
