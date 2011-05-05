------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--          A D A . R E A L _ T I M E . T I M I N G _ E V E N T S           --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                Copyright (C) 2008, Kristoffer N. Gregertsen              --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
-- to  the  Free Software Foundation,  51  Franklin  Street,  Fifth  Floor, --
-- Boston, MA 02110-1301, USA.                                              --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Unchecked_Conversion;
with System.BB.Protection;

package body Ada.Real_Time.Timing_Events is

   package Protection renames System.BB.Protection;
   package SBT renames System.BB.Time;

   use type SBT.Alarm_Id;

   type Timing_Event_Access is access all Timing_Event;

   --------------------
   -- Local routines --
   --------------------

   procedure Execute_Handler (Event_Address : System.Address);

   procedure Initialize (Event : in out Timing_Event);

   function To_Access is new Ada.Unchecked_Conversion
        (System.Address, Timing_Event_Access);

   ---------------------
   -- Execute_Handler --
   ---------------------

   procedure Execute_Handler (Event_Address : System.Address) is
      Event : constant Timing_Event_Access := To_Access (Event_Address);
   begin

      pragma Assert (Event /= null and then Event.Handler /= null);

      declare
         Handler : constant Timing_Event_Handler := Event.Handler;
      begin
         Event.Handler := null;
         Handler (Event.all);
      end;

   end Execute_Handler;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Event : in out Timing_Event) is
   begin
      Protection.Enter_Kernel;

      Event.Id := Event.Alarm'Unchecked_Access;

      SBT.Initialize_Alarm (Event.Id,
                            Execute_Handler'Access,
                            Event'Address);

      Protection.Leave_Kernel_No_Change;

   end Initialize;

   -----------------
   -- Set_Handler --
   -----------------

   procedure Set_Handler
     (Event   : in out Timing_Event;
      At_Time : Time;
      Handler : Timing_Event_Handler)
   is
   begin

      if Event.Id = null then
         Initialize (Event);
      end if;

      Protection.Enter_Kernel;

      Event.Handler := Handler;

      SBT.Cancel (Event.Id);

      if Handler /= null then
         SBT.Set (Event.Id, SBT.Time (At_Time));
      end if;

      Protection.Leave_Kernel_No_Change;

   end Set_Handler;

   -----------------
   -- Set_Handler --
   -----------------

   procedure Set_Handler
     (Event   : in out Timing_Event;
      In_Time : Time_Span;
      Handler : Timing_Event_Handler)
   is
   begin
      Set_Handler (Event, Clock + In_Time, Handler);
   end Set_Handler;

   ---------------------
   -- Current_Handler --
   ---------------------

   function Current_Handler
     (Event : Timing_Event) return Timing_Event_Handler
   is
   begin
      return Event.Handler;
   end Current_Handler;

   --------------------
   -- Cancel_Handler --
   --------------------

   procedure Cancel_Handler
     (Event     : in out Timing_Event;
      Cancelled : out Boolean)
   is
   begin

      Protection.Enter_Kernel;

      if Event.Id = null then
         Initialize (Event);
      end if;

      SBT.Cancel (Event.Id);

      Cancelled     := Event.Handler /= null;
      Event.Handler := null;

      Protection.Leave_Kernel_No_Change;

   end Cancel_Handler;

   -------------------
   -- Time_Of_Event --
   -------------------

   function Time_Of_Event (Event : Timing_Event) return Time is
   begin

      if Event.Id = null then
         return Time'First;
      end if;

      return Time (SBT.Time_Of_Alarm (Event.Id));

   end Time_Of_Event;

end Ada.Real_Time.Timing_Events;
