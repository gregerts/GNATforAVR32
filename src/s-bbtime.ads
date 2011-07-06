------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                         S Y S T E M . B B . T I M E                      --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2004 The European Space Agency            --
--                     Copyright (C) 2003-2007, AdaCore                     --
--             Copyright (C) 2008-2011, Kristoffer N. Gregertsen            --
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

--  Package in charge of implementing clock and timer functionalities

pragma Restrictions (No_Elaboration_Code);

with System.BB.Peripherals;
--  Used for Main_Clock_Frequency

with System.BB.Interrupts;
--  Used for Interrupt_ID

limited with System.BB.Threads;
--  Used for limited view of Thread_Descriptor

package System.BB.Time is

   pragma Preelaborate;

   type Time is mod 2 ** 64;
   for Time'Size use 64;
   --  Time is represented at this level as a 64-bit natural number

   type Time_Span is range -2 ** 63 .. 2 ** 63 - 1;
   for Time_Span'Size use 64;
   --  Time_Span represents the length of time intervals, and it is
   --  defined as a 64-bit signed integer.

   ----------------
   -- Identities --
   ----------------

   type Thread_Id is not null access all System.BB.Threads.Thread_Descriptor;

   subtype Interrupt_ID is System.BB.Interrupts.Interrupt_ID;

   ---------------
   -- Constants --
   ---------------

   Tick : constant := 1;
   --  A clock tick is a real time interval during which the clock value (as
   --  observed by calling the Clock function) remains constant. Tick is the
   --  average length of such intervals.

   Ticks_Per_Second : constant := Peripherals.Main_Clock_Frequency;
   --  Number of ticks (or clock interrupts) per second

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

   procedure Initialize_Timers (Environment_Thread : Thread_Id);
   --  Initializes the real-time clock and the clock of the
   --  environment thread. Must be called before any other functions.

   ----------------------
   -- Clock operations --
   ----------------------

   function Clock (Alarm : not null Alarm_Id) return Clock_Id;
   pragma Inline_Always (Clock);
   --  Returns the clock of the given alarm

   function Elapsed_Time (Clock : not null Clock_Id) return Time;
   pragma Inline (Elapsed_Time);
   --  Returns the elapsed time of the given clock

   function Interrupt_Clock (Id : Interrupt_ID) return Clock_Id;
   pragma Inline_Always (Interrupt_Clock);
   --  Returns the execution time clock for the given interrupt ID

   function Monotonic_Clock return Time;
   pragma Inline (Monotonic_Clock);
   --  Returns the elapsed time of the real-time clock

   function Real_Time_Clock return Clock_Id;
   pragma Inline_Always (Real_Time_Clock);
   --  Returns the real time clock

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
      Timeout : Time);
   --  Set alarm timer

   function Time_Of_Alarm (Alarm : not null Alarm_Id) return Time;
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
         Base_Time : Time;
         --  pragma Volatile (Base_Time);
         --  Base time of clock

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
         Timeout : Time;
         --  Timeout of alarm when set

         Clock : Clock_Id;
         --  Clock of this alarm

         Handler : Alarm_Handler;
         --  Handler to be called when the alarm expires

         Data : System.Address;
         --  Argument to be given when calling handler

         Next : Alarm_Id;
         --  Next alarm in queue when set, null otherwise

      end record;

   pragma Suppress_Initialization (Alarm_Descriptor);

end System.BB.Time;
