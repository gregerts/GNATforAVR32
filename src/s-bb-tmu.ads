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
   -- Clock --
   -----------

   type Clock_Descriptor is limited private;

   type Clock_Id is access all Clock_Descriptor;

   ----------------------
   -- Alarm_Descriptor --
   ----------------------

   type Alarm_Descriptor is limited private;

   type Alarm_Id is access all Alarm_Descriptor;

   type Alarm_Handler is access procedure (Data : System.Address);

   --------------------
   -- Initialization --
   --------------------

   procedure Initialize_Interrupt_Clock (Id : Interrupt_ID);
   --  Initializes the clock for the given interrupt ID

   procedure Initialize_Thread_Clock (Id : Thread_Id);
   --  Initializes the clock for the given thread

   procedure Initialize_TMU (Environment_Thread : Thread_Id);
   --  Initialize this package. Must be called before any other
   --  procedures and functions in this package.

   ----------------------
   -- Clock operations --
   ----------------------

   function Clock (Alarm : not null Alarm_Id) return Clock_Id;
   pragma Inline_Always (Clock);
   --  Returns the clock of the given alarm

   function Interrupt_Clock (Id : Interrupt_ID) return Clock_Id;
   pragma Inline_Always (Interrupt_Clock);
   --  Returns the execution time clock for the given interrupt ID

   function Time_Of_Clock (Clock : not null Clock_Id) return CPU_Time;
   pragma Inline (Time_Of_Clock);
   --  Returns the time of the given clock

   function Thread_Clock (Id : Thread_Id) return Clock_Id;
   pragma Inline_Always (Thread_Clock);
   --  Returns execution time clock for the given thread

   ----------------------
   -- Alarm operations --
   ----------------------

   procedure Initialize_Alarm
     (Alarm   : not null Alarm_Id;
      Clock   : not null Clock_Id;
      Handler : not null Alarm_Handler;
      Data    : System.Address;
      Success : out Boolean);
   --  Initializes alarm with the given clock, handler and data

   procedure Cancel (Alarm : not null Alarm_Id);
   --  Cancel alarm timer

   procedure Set
     (Alarm   : not null Alarm_Id;
      Timeout : CPU_Time);
   --  Set alarm timer

   function Time_Of_Alarm (Alarm : not null Alarm_Id) return CPU_Time;
   pragma Inline (Time_Of_Alarm);
   --  Get expiration time of alarm

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

   ----------------------
   -- Clock_Descriptor --
   ----------------------

   type Clock_Descriptor is
      record
         Count : CPU_Time;
         --  Count value of clock if not active

         First_Alarm : Alarm_Id;
         --  Points to the first alarm of this clock

         Capacity : Natural;
         --  Remaining alarm capacity, no more alarms allowed if zero

      end record;

   pragma Suppress_Initialization (Clock_Descriptor);

   ----------------------
   -- Alarm_Descriptor --
   ----------------------

   type Alarm_Descriptor is
      record
         Timeout : CPU_Time;
         --  Timeout of alarm when set

         Clock : Clock_Id;
         --  Clock of this alarm

         Handler : Alarm_Handler;
         --  Handler to be called when the alarm expires

         Data : System.Address;
         --  Argument to be given when calling handler

      end record;

   pragma Suppress_Initialization (Alarm_Descriptor);

end System.BB.TMU;
