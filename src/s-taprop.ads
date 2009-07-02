------------------------------------------------------------------------------
--                                                                          --
--                 GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                 --
--                                                                          --
--     S Y S T E M . T A S K _ P R I M I T I V E S .O P E R A T I O N S     --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--                     Copyright (C) 2001-2007, AdaCore                     --
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

--  This is the version of this package for Ravenscar bare board targets

--  This package contains all the GNULL primitives that interface directly
--  with the underlying OS.

pragma Restrictions (No_Elaboration_Code);

with System.OS_Interface;
--  used for Time

with System.BB.TMU;
--  used for Timer_Id
--           CPU_Time

with System.Parameters;
--  used for Size_Type

with System.Tasking;
--  used for Task_Id

package System.Task_Primitives.Operations is
   pragma Preelaborate;

   package ST renames System.Tasking;

   --  See s-taprop.ads for up to date specs of the following subprograms

   procedure Initialize (Environment_Task : ST.Task_Id);
   pragma Inline (Initialize);

   procedure Create_Task
     (T          : ST.Task_Id;
      Wrapper    : System.Address;
      Stack_Size : System.Parameters.Size_Type;
      Priority   : System.Any_Priority;
      Succeeded  : out Boolean);
   pragma Inline (Create_Task);

   procedure Enter_Task (Self_ID : ST.Task_Id);
   pragma Inline (Enter_Task);

   procedure Initialize_TCB (Self_ID : ST.Task_Id; Succeeded : out Boolean);
   pragma Inline (Initialize_TCB);

   function Self return ST.Task_Id;
   pragma Inline (Self);

   procedure Set_Priority
     (T    : ST.Task_Id;
      Prio : System.Any_Priority);
   pragma Inline (Set_Priority);

   function Get_Priority (T : ST.Task_Id) return System.Any_Priority;
   pragma Inline (Get_Priority);

   type Time is new System.OS_Interface.Time;

   function Monotonic_Clock return Time;
   pragma Inline (Monotonic_Clock);

   RT_Resolution : constant := System.OS_Interface.Ticks_Per_Second;
   --  Number of ticks per second

   ----------------
   -- Extensions --
   ----------------

   procedure Sleep
     (Self_ID : ST.Task_Id;
      Reason  : System.Tasking.Task_States);
   pragma Inline (Sleep);
   --  The caller should hold no lock when calling this procedure

   procedure Delay_Until (Abs_Time : Time);
   pragma Inline (Delay_Until);

   procedure Wakeup
     (T      : ST.Task_Id;
      Reason : System.Tasking.Task_States);
   pragma Inline (Wakeup);
   --  The caller should hold no lock when calling this procedure

   function Is_Task_Context return Boolean;
   pragma Inline (Is_Task_Context);
   --  This function returns True if the current execution is in the context
   --  of a task, and False if it is an interrupt context.

   ---------
   -- TMU --
   ---------

   function Task_Clock (T : ST.Task_Id) return System.BB.TMU.Clock_Id;
   pragma Inline (Task_Clock);
   --  This function returns the exeuction time of the given task

   procedure Enter_Proxy (T : ST.Task_Id);
   pragma Inline (Enter_Proxy);
   --  Enter proxy timing mode for the given task

   procedure Leave_Proxy renames System.BB.TMU.Leave_Proxy;
   --  Leave proxy timing mode

end System.Task_Primitives.Operations;
