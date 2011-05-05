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
--             Copyright (C) 2008-2009, Kristoffer N. Gregertsen            --
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

package System.BB.Time is

   pragma Preelaborate;

   type Time is mod 2 ** 64;
   for Time'Size use 64;
   --  Time is represented at this level as a 64-bit natural number

   type Time_Span is range -2 ** 63 .. 2 ** 63 - 1;
   for Time_Span'Size use 64;
   --  Time_Span represents the length of time intervals, and it is
   --  defined as a 64-bit signed integer.

   ---------------
   -- Constants --
   ---------------

   Tick : constant := 1;
   --  A clock tick is a real time interval during which the clock value (as
   --  observed by calling the Clock function) remains constant. Tick is the
   --  average length of such intervals.

   Ticks_Per_Second : constant := Peripherals.Main_Clock_Frequency;
   --  Number of ticks (or clock interrupts) per second

   ----------------------
   -- Alarm_Descriptor --
   ----------------------

   type Alarm_Descriptor is limited private;

   type Alarm_Id is access all Alarm_Descriptor;

   type Alarm_Handler is access procedure (Data : System.Address);

   --------------------
   -- Initialization --
   --------------------

   procedure Initialize_Timers;
   --  Initializes the real-time clock. Must be called before any
   --  other functions.

   ----------------------
   -- Clock operations --
   ----------------------

   function Monotonic_Clock return Time;
   pragma Inline (Monotonic_Clock);
   --  Returns time of the real-time clock

   ----------------------
   -- Alarm operations --
   ----------------------

   procedure Initialize_Alarm
     (Alarm   : not null Alarm_Id;
      Handler : not null Alarm_Handler;
      Data    : System.Address);
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

private

   ----------------------
   -- Alarm_Descriptor --
   ----------------------

   type Alarm_Descriptor is
      record
         Timeout : Time;
         --  Timeout of alarm when set

         Handler : Alarm_Handler;
         --  Handler to be called when the alarm expires

         Data : System.Address;
         --  Argument to be given when calling handler

         Next : Alarm_Id;
         --  Next alarm in queue when set, null otherwise

      end record;

   pragma Suppress_Initialization (Alarm_Descriptor);

end System.BB.Time;
