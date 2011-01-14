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

   subtype CPU_Time is Peripherals.TMU_Interval;
   --  Type representing of CPU time

   CPU_Tick : constant := 1;
   --  Smallest amount of execution time representable by the CPU_Time

   CPU_Ticks_Per_Second : constant := Peripherals.TMU_Frequency;
   --  Number of CPU ticks per second

   ----------------
   -- Identities --
   ----------------

   type Thread_Id is not null access all System.BB.Threads.Thread_Descriptor;

   subtype Interrupt_ID is System.BB.Interrupts.Interrupt_ID;

   -----------
   -- Timer --
   -----------

   type Timer_Descriptor is limited private;

   type Timer_Id is access all Timer_Descriptor;

   type Timer_Handler is access procedure (Data : System.Address);

   --------------------
   -- Initialization --
   --------------------

   procedure Initialize_Interrupt_Timer (Id : Interrupt_ID);
   --  Initializes the timer for the given interrupt ID

   procedure Initialize_Thread_Timer (Id : Thread_Id);
   --  Initializes the timer for the given thread

   procedure Initialize_TMU (Environment_Thread : Thread_Id);
   --  Initialize this package. Must be called before any other
   --  procedures and functions in this package.

   ----------------------
   -- Timer operations --
   ----------------------

   procedure Bind
     (TM      : Timer_Id;
      Handler : Timer_Handler;
      Data    : System.Address;
      Success : out Boolean);
   --  Binds the timer to the given handler and data. Success set to
   --  false if the timer is already bound.

   procedure Cancel (TM : Timer_Id);
   --  Cancels the timer

   function Clock (TM : Timer_Id) return CPU_Time;
   pragma Inline_Always (Clock);
   --  Returns the execution time clock for the given timer

   function Interrupt_Timer (Id : Interrupt_ID) return Timer_Id;
   pragma Inline_Always (Interrupt_Timer);
   --  Get the timer associated with the given interrupt

   procedure Set
     (TM      : Timer_Id;
      Timeout : CPU_Time);
   --  Sets the timer, may overwrite an already pending timeout

   function Thread_Timer (Id : Thread_Id) return Timer_Id;
   pragma Inline_Always (Thread_Timer);
   --  Get the timer associated with the given thread

   function Time_Remaining (TM : Timer_Id) return CPU_Time;
   --  Returns time remaining before timeout or 0 if no timeout

   -------------------------
   -- Internal operations --
   -------------------------

   procedure Enter_Idle (Id : Thread_Id);
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

   type Timer_State is (Uninitialized, Free, Cleared, Set);

   ----------------------
   -- Timer_Descriptor --
   ----------------------

   type Timer_Descriptor is
      record
         Compare : CPU_Time;
         --  Timeout if timer is set, else CPU_Time'Last

         Count : CPU_Time;
         --  Current time of clock if not active

         Handler : Timer_Handler;
         --  Handler to be called when the timer expires

         Data : System.Address;
         --  Argument to be given when calling handler

         State : Timer_State;
         --  State of the timer, initially uninitialized

      end record;

   pragma Suppress_Initialization (Timer_Descriptor);

end System.BB.TMU;
