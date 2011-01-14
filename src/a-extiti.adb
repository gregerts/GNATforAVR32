------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--             A D A . E X E C U T I O N _ T I M E . T I M E R S            --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                Copyright (C) 2008, Kristoffer N. Gregertsen              --
--                                                                          --
-- This specification is derived from the Ada Reference Manual for use with --
-- GNAT. The copyright notice above, and the license provisions that follow --
-- apply solely to the  contents of the part following the private keyword. --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
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
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Execution_Time.Interrupts.Timers;
with Ada.Unchecked_Conversion;
with System.Tasking;
with System.Task_Primitives.Operations;
with System.BB.Protection;

package body Ada.Execution_Time.Timers is

   package Protection renames System.BB.Protection;
   package STPO renames System.Task_Primitives.Operations;
   package TMU renames System.BB.TMU;
   package EIT renames Ada.Execution_Time.Interrupts.Timers;

   use type TMU.Timer_Id;
   use type Ada.Task_Identification.Task_Id;

   type Timer_Access is access all Timer;

   --------------------
   -- Local routines --
   --------------------

   procedure Execute_Handler (Timer_Address : System.Address);

   procedure Initialize (TM : in out Timer'Class);

   function To_Task_Id is new Ada.Unchecked_Conversion
     (Ada.Task_Identification.Task_Id, System.Tasking.Task_Id);

   function To_Access is new Ada.Unchecked_Conversion
     (System.Address, Timer_Access);

   --------------------
   -- Cancel_Handler --
   --------------------

   procedure Cancel_Handler
     (TM        : in out Timer;
      Cancelled :    out Boolean)
   is
   begin

      if TM.Id = null then
         Initialize (TM);
      end if;

      Protection.Enter_Kernel;

      TMU.Cancel (TM.Id);

      Cancelled  := TM.Handler /= null;
      TM.Handler := null;

      Protection.Leave_Kernel_No_Change;

   end Cancel_Handler;

   ---------------------
   -- Current_Handler --
   ---------------------

   function Current_Handler (TM : Timer) return Timer_Handler is
   begin
      return TM.Handler;
   end Current_Handler;

   ---------------------
   -- Execute_Handler --
   ---------------------

   procedure Execute_Handler (Timer_Address : System.Address) is
      TM : constant Timer_Access := To_Access (Timer_Address);
   begin

      pragma Assert (TM /= null and then TM.Handler /= null);

      declare
         Handler : constant Timer_Handler := TM.Handler;
      begin
         TM.Handler := null;
         Handler (TM.all);
      end;

   end Execute_Handler;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (TM : in out Timer'Class) is
      Success : Boolean;
   begin

      pragma Assert (TM.Id = null);

      if TM in EIT.Timer'Class then
         TM.Id := TMU.Interrupt_Timer (TMU.Interrupt_ID (EIT.Timer (TM).I));
      else
         TM.Id := STPO.Task_Timer (To_Task_Id (TM.T.all));
      end if;

      Protection.Enter_Kernel;

      TMU.Bind (TM.Id, Execute_Handler'Access, TM'Address, Success);

      Protection.Leave_Kernel_No_Change;

      if not Success then
         TM.Id := null;
         raise Timer_Resource_Error;
      end if;

   end Initialize;

   -----------------
   -- Set_Handler --
   -----------------

   procedure Set_Handler
     (TM      : in out Timer;
      In_Time : Ada.Real_Time.Time_Span;
      Handler : Timer_Handler)
   is
      At_Time : CPU_Time;
   begin

      if TM.Id = null then
         Initialize (TM);
      end if;

      At_Time := CPU_Time (TMU.Clock (TM.Id)) + In_Time;

      Set_Handler (TM, At_Time, Handler);

   end Set_Handler;

   -----------------
   -- Set_Handler --
   -----------------

   procedure Set_Handler
     (TM      : in out Timer;
      At_Time : CPU_Time;
      Handler : Timer_Handler)
   is
   begin

      if TM.Id = null then
         Initialize (TM);
      end if;

      Protection.Enter_Kernel;

      TM.Handler := Handler;

      if Handler /= null then
         TMU.Set (TM.Id, TMU.CPU_Time (At_Time));
      else
         TMU.Cancel (TM.Id);
      end if;

      Protection.Leave_Kernel_No_Change;

   end Set_Handler;

   --------------------
   -- Time_Remaining --
   --------------------

   function Time_Remaining (TM : Timer) return Ada.Real_Time.Time_Span is
   begin

      if TM.Id = null then
         return Ada.Real_Time.Time_Span_Zero;
      end if;

      return CPU_Time (TMU.Time_Remaining (TM.Id)) - 0;

   end Time_Remaining;

end Ada.Execution_Time.Timers;
