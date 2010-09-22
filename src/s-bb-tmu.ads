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

   ----------------
   -- Identities --
   ----------------

   type Thread_Id is not null access all System.BB.Threads.Thread_Descriptor;

   subtype Interrupt_ID is System.BB.Interrupts.Interrupt_ID;

   ----------------------
   -- Clock_Descriptor --
   ----------------------

   type Clock_Descriptor is limited private;

   type Clock_Id is access all Clock_Descriptor;

   ----------------------
   -- Timer_Descriptor --
   ----------------------

   type Timer_Descriptor (Clock : not null Clock_Id) is private;

   type Timer_Id is access all Timer_Descriptor;

   type Timer_Handler is access procedure (Data : System.Address);

   --------------------
   -- Initialization --
   --------------------

   procedure Initialize_Interrupt (Id : Interrupt_ID);
   --  Initializes the clock for the given interrupt ID

   procedure Initialize_Clock (Clock : Clock_Id);
   --  Initializes the given Clock

   procedure Initialize_TMU (Environment_Clock : Clock_Id);
   --  Initialize this package. Must be called before any other
   --  procedures and functions in this package.

   ----------------------
   -- Clock operations --
   ----------------------

   function Thread_Clock (Id : Thread_Id) return Clock_Id;
   pragma Inline_Always (Thread_Clock);
   --  Returns execution time clock for the given thread

   function Interrupt_Clock (Id : Interrupt_ID) return Clock_Id;
   pragma Inline_Always (Interrupt_Clock);
   --  Returns the execution time clock for the given interrupt ID

   function Time_Of (Clock : Clock_Id) return CPU_Time;
   --  Get execution time of the given clock

   ----------------------
   -- Timer operations --
   ----------------------

   function Create
     (Clock   : not null Clock_Id;
      Handler : not null Timer_Handler;
      Data    : System.Address) return Timer_Id;
   --  Creates a timer for the given clock with the given handler and
   --  data. Return null if the clock already has a timer.

   procedure Cancel (TM : Timer_Id);
   --  Cancels the timer

   procedure Set
     (TM      : Timer_Id;
      Timeout : CPU_Time);
   --  Sets the timer, may overwrite an already pending timeout

   function Time_Remaining (TM : Timer_Id) return CPU_Time;
   --  Returns time remaining before timeout or 0 if no timeout

   -------------------------
   -- Internal operations --
   -------------------------

   procedure Enter_Idle;
   pragma Inline (Enter_Idle);
   --  Enter idle mode

   procedure Enter_Interrupt (Id : Interrupt_ID);
   pragma Inline (Enter_Interrupt);
   --  Enter interrupt mode

   procedure Leave_Idle (Id : Thread_Id);
   pragma Inline (Leave_Idle);
   --  Leave idle mode

   procedure Leave_Interrupt;
   pragma Inline (Leave_Interrupt);
   --  Leave interrupt mode

private

   type Clock_Descriptor is
      record
         Base_Time : CPU_Time;
         pragma Volatile (Base_Time);
         --  Base time, updated when the clock is deactivated

         First_TM : Timer_Id;
         --  First timer of this clock, or null if no set timer

         Free : Natural;
         --  Remaining number of timers allowed for this clock

      end record;

   pragma Suppress_Initialization (Clock_Descriptor);

   type Timer_Descriptor (Clock : not null Clock_Id) is
      record
         Handler : Timer_Handler;
         --  Handler to be called when the timer expires

         Data : System.Address;
         --  Argument to be given when calling handler

         Timeout : CPU_Time;
         --  Timeout of timer or CPU_Time'First if timer is not set

      end record;

end System.BB.TMU;
