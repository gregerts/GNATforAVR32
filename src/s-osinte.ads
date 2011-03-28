------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                    S Y S T E M . O S _ I N T E R F A C E                 --
--                                                                          --
--                                   S p e c                                --
--                                                                          --
--             Copyright (C) 1991-1994, Florida State University            --
--             Copyright (C) 1995-2007, Free Software Foundation, Inc.      --
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
------------------------------------------------------------------------------

--  This is the Ravenscar version of this package for a bare board
--  AVR32/UC3 target

--  This package encapsulates all direct interfaces to OS services
--  that are needed by children of System.

pragma Restrictions (No_Elaboration_Code);

with System.Parameters;
--  Used for Size_Type

with System.BB.Threads;
--  Used for Thread_Id
--           Thread_Descriptor
--           Create_Task
--           Set_Priority
--           Get_Priority
--           Delay_Until
--           Sleep
--           Wakeup
--           Get_ATCB
--           Set_ATCB

with System.BB.Time;
--  Used for Time
--           Clock
--           Ticks_Per_Second

with System.BB.Interrupts;
--  Used for Max_Interrupt
--           Interrupt_ID
--           Interrupt_Level
--           Priority_Of_Interrupt
--           Attach_Handler

with System.BB.Peripherals;
--  Used for interrupt names

package System.OS_Interface is
   pragma Preelaborate;

   package SBP renames System.BB.Peripherals;

   ----------------
   -- Interrupts --
   ----------------

   Max_Interrupt : constant := System.BB.Interrupts.Max_Interrupt;
   --  Number of asynchronous interrupts

   subtype Interrupt_ID is System.BB.Interrupts.Interrupt_ID;
   --  Interrupt identifiers

   subtype Interrupt_Level is System.BB.Interrupts.Interrupt_Level;
   --  Interrupt levels

   No_Interrupt : constant Interrupt_ID := System.BB.Interrupts.No_Interrupt;
   --  Special value indicating no interrupt

   subtype Interrupt_Handler is System.BB.Interrupts.Interrupt_Handler;
   --  Interrupt handlers

   ---------------------------
   -- Peripheral Interrupts --
   ---------------------------

   --  Group 18
   SDRAMC           : constant := SBP.SDRAMC;
   SDRAMC_Priority  : constant := Interrupt_Priority'First;
   --  Group 17
   USB              : constant := SBP.USB;
   USB_Priority     : constant := Interrupt_Priority'First;
   --  Group 16
   MACB             : constant := SBP.MACB;
   MACB_Priority    : constant := Interrupt_Priority'First;
   --  Group 15
   ADC              : constant := SBP.ADC;
   ADC_Priority     : constant := Interrupt_Priority'First;
   --  Group 14
   TC_2             : constant := SBP.TC_2;
   TC_2_Priority    : constant := Interrupt_Priority'First + 3;
   TC_1             : constant := SBP.TC_1;
   TC_1_Priority    : constant := Interrupt_Priority'First + 3;
   TC_0             : constant := SBP.TC_0;
   TC_0_Priority    : constant := Interrupt_Priority'First + 3;
   --  Group 13
   SSC              : constant := SBP.SSC;
   SSC_Priority     : constant := Interrupt_Priority'First;
   --  Group 12
   PWM              : constant := SBP.PWM;
   PWM_Priority     : constant := Interrupt_Priority'First;
   --  Group 11
   TWI              : constant := SBP.TWI;
   TWI_Priority     : constant := Interrupt_Priority'First;
   --  Group 10
   SPI_1            : constant := SBP.SPI_1;
   SPI_1_Priority   : constant := Interrupt_Priority'First;
   --  Group 9
   SPI_0            : constant := SBP.SPI_0;
   SPI_0_Priority   : constant := Interrupt_Priority'First;
   --  Group 8
   USART_3          : constant := SBP.USART_3;
   USART_3_Priority : constant := Interrupt_Priority'First;
   --  Group 7
   USART_2          : constant := SBP.USART_2;
   USART_2_Priority : constant := Interrupt_Priority'First;
   --  Group 6
   USART_1          : constant := SBP.USART_1;
   USART_1_Priority : constant := Interrupt_Priority'First;
   --  Group 5
   USART_0          : constant := SBP.USART_0;
   USART_0_Priority : constant := Interrupt_Priority'First;
   --  Group 4
   FLASHC           : constant := SBP.FLASHC;
   FLASHC_Priority  : constant := Interrupt_Priority'First;
   --  Group 3
   PDCA_14          : constant := SBP.PDCA_14;
   PDCA_14_Priority : constant := Interrupt_Priority'First;
   PDCA_13          : constant := SBP.PDCA_13;
   PDCA_13_Priority : constant := Interrupt_Priority'First;
   PDCA_12          : constant := SBP.PDCA_12;
   PDCA_12_Priority : constant := Interrupt_Priority'First;
   PDCA_11          : constant := SBP.PDCA_11;
   PDCA_11_Priority : constant := Interrupt_Priority'First;
   PDCA_10          : constant := SBP.PDCA_10;
   PDCA_10_Priority : constant := Interrupt_Priority'First;
   PDCA_9           : constant := SBP.PDCA_9;
   PDCA_9_Priority  : constant := Interrupt_Priority'First;
   PDCA_8           : constant := SBP.PDCA_8;
   PDCA_8_Priority  : constant := Interrupt_Priority'First;
   PDCA_7           : constant := SBP.PDCA_7;
   PDCA_7_Priority  : constant := Interrupt_Priority'First;
   PDCA_6           : constant := SBP.PDCA_6;
   PDCA_6_Priority  : constant := Interrupt_Priority'First;
   PDCA_5           : constant := SBP.PDCA_5;
   PDCA_5_Priority  : constant := Interrupt_Priority'First;
   PDCA_4           : constant := SBP.PDCA_4;
   PDCA_4_Priority  : constant := Interrupt_Priority'First;
   PDCA_3           : constant := SBP.PDCA_3;
   PDCA_3_Priority  : constant := Interrupt_Priority'First;
   PDCA_2           : constant := SBP.PDCA_2;
   PDCA_2_Priority  : constant := Interrupt_Priority'First;
   PDCA_1           : constant := SBP.PDCA_1;
   PDCA_1_Priority  : constant := Interrupt_Priority'First;
   PDCA_0           : constant := SBP.PDCA_0;
   PDCA_0_Priority  : constant := Interrupt_Priority'First;
   --  Group 2
   GPIO_13          : constant := SBP.GPIO_13;
   GPIO_13_Priority : constant := Interrupt_Priority'First;
   GPIO_12          : constant := SBP.GPIO_12;
   GPIO_12_Priority : constant := Interrupt_Priority'First;
   GPIO_11          : constant := SBP.GPIO_11;
   GPIO_11_Priority : constant := Interrupt_Priority'First;
   GPIO_10          : constant := SBP.GPIO_10;
   GPIO_10_Priority : constant := Interrupt_Priority'First;
   GPIO_9           : constant := SBP.GPIO_9;
   GPIO_9_Priority  : constant := Interrupt_Priority'First;
   GPIO_8           : constant := SBP.GPIO_8;
   GPIO_8_Priority  : constant := Interrupt_Priority'First;
   GPIO_7           : constant := SBP.GPIO_7;
   GPIO_7_Priority  : constant := Interrupt_Priority'First;
   GPIO_6           : constant := SBP.GPIO_6;
   GPIO_6_Priority  : constant := Interrupt_Priority'First;
   GPIO_5           : constant := SBP.GPIO_5;
   GPIO_5_Priority  : constant := Interrupt_Priority'First;
   GPIO_4           : constant := SBP.GPIO_4;
   GPIO_4_Priority  : constant := Interrupt_Priority'First;
   GPIO_3           : constant := SBP.GPIO_3;
   GPIO_3_Priority  : constant := Interrupt_Priority'First;
   GPIO_2           : constant := SBP.GPIO_2;
   GPIO_2_Priority  : constant := Interrupt_Priority'First;
   GPIO_1           : constant := SBP.GPIO_1;
   GPIO_1_Priority  : constant := Interrupt_Priority'First;
   GPIO_0           : constant := SBP.GPIO_0;
   GPIO_0_Priority  : constant := Interrupt_Priority'First;
   --  Group 1
   FREQM            : constant := SBP.FREQM;
   FREQM_Priority   : constant := Interrupt_Priority'First;
   PM               : constant := SBP.PM;
   PM_Priority      : constant := Interrupt_Priority'First;
   RTC              : constant := SBP.RTC;
   RTC_Priority     : constant := Interrupt_Priority'First;
   EIM_7            : constant := SBP.EIM_7;
   EIM_7_Priority   : constant := Interrupt_Priority'First;
   EIM_6            : constant := SBP.EIM_6;
   EIM_6_Priority   : constant := Interrupt_Priority'First;
   EIM_5            : constant := SBP.EIM_5;
   EIM_5_Priority   : constant := Interrupt_Priority'First;
   EIM_4            : constant := SBP.EIM_4;
   EIM_4_Priority   : constant := Interrupt_Priority'First;
   EIM_3            : constant := SBP.EIM_3;
   EIM_3_Priority   : constant := Interrupt_Priority'First;
   EIM_2            : constant := SBP.EIM_2;
   EIM_2_Priority   : constant := Interrupt_Priority'First;
   EIM_1            : constant := SBP.EIM_1;
   EIM_1_Priority   : constant := Interrupt_Priority'First;
   EIM_0            : constant := SBP.EIM_0;
   EIM_0_Priority   : constant := Interrupt_Priority'First;
   --  Group 0
   COMPARE          : constant := SBP.COMPARE;
   COMPARE_Priority : constant := Interrupt_Priority'First + 3;

   --------------------------
   -- Interrupt processing --
   --------------------------

   function Current_Interrupt return Interrupt_ID
     renames System.BB.Interrupts.Current_Interrupt;
   --  Function that returns the hardware interrupt currently being
   --  handled (if any). In case no hardware interrupt is being handled
   --  the returned value is No_Interrupt.

   function Priority_Of_Interrupt (Id : Interrupt_ID) return Any_Priority
     renames System.BB.Interrupts.Priority_Of_Interrupt;
   --  Obtain the software priority of any hardware interrupt. This makes
   --  easier the selection of the priority of the protected handler
   --  attached to interrupts.

   procedure Attach_Handler
     (Handler : Interrupt_Handler;
      Id      : Interrupt_ID) renames System.BB.Interrupts.Attach_Handler;
   --  Attach a handler to a hardware interrupt

   ----------
   -- Time --
   ----------

   subtype Time is System.BB.Time.Time;
   --  Representation of the time in the underlying tasking system

   subtype Time_Span is System.BB.Time.Time_Span;
   --  Represents the length of time intervals in the underlying tasking
   --  system.

   Ticks_Per_Second : constant := System.BB.Time.Ticks_Per_Second;
   --  Number of ticks (or clock interrupts) per second

   function Clock return Time renames System.BB.Time.Monotonic_Clock;
   --  Get the number of ticks elapsed since startup

   -------------
   -- Threads --
   -------------

   subtype Thread_Descriptor is System.BB.Threads.Thread_Descriptor;
   --  Type that contains the information about a thread (registers,
   --  priority, etc.).

   subtype Thread_Id is System.BB.Threads.Thread_Id;
   --  Identifiers for the underlying threads

   Null_Thread_Id : constant Thread_Id := null;
   --  Identifier for a non valid thread

   procedure Initialize
     (Environment_Thread : Thread_Id;
      Main_Priority      : System.Any_Priority)
     renames System.BB.Threads.Initialize;
   --  Procedure for initializing the underlying tasking system

   procedure Thread_Create
     (Id            : Thread_Id;
      Code          : System.Address;
      Arg           : System.Address;
      Priority      : System.Any_Priority;
      Stack_Address : System.Address;
      Stack_Size    : System.Parameters.Size_Type)
     renames System.BB.Threads.Thread_Create;
   --  Create a new thread

   function Thread_Self return Thread_Id renames System.BB.Threads.Thread_Self;
   --  Return the thread identifier for the calling task

   ----------
   -- ATCB --
   ----------

   procedure Set_ATCB (ATCB : System.Address)
     renames System.BB.Threads.Set_ATCB;
   --  Associate the specified ATCB to the currently running thread

   function Get_ATCB return System.Address renames System.BB.Threads.Get_ATCB;
   --  Get the ATCB associated to the currently running thread

   ----------------
   -- Scheduling --
   ----------------

   procedure Set_Priority (Priority  : System.Any_Priority)
     renames System.BB.Threads.Set_Priority;
   --  Set the active priority of the executing thread to the given value

   function Get_Priority  (Id : Thread_Id) return System.Any_Priority
     renames System.BB.Threads.Get_Priority;
   --  Get the current base priority of a thread

   procedure Delay_Until (T : Time) renames System.BB.Threads.Delay_Until;
   --  Suspend the calling task until the absolute time specified by T

   procedure Sleep renames System.BB.Threads.Sleep;
   --  The calling thread is unconditionally suspended

   procedure Wakeup (Id : Thread_Id) renames System.BB.Threads.Wakeup;
   --  The referred thread becomes ready (the thread must be suspended)

end System.OS_Interface;
