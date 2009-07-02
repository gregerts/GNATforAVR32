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

   type Timing_Event_Access is access all Timing_Event;

   --------------------
   -- Local routines --
   --------------------

   procedure Execute_Handler (Event_Address : System.Address);

   function To_Access is new Ada.Unchecked_Conversion
        (System.Address, Timing_Event_Access);

   ---------------------
   -- Execute_Handler --
   ---------------------

   procedure Execute_Handler (Event_Address : System.Address) is
      Event : constant Timing_Event_Access := To_Access (Event_Address);
      Handler : Timing_Event_Handler;

   begin

      pragma Assert (Event /= null and then Event.Handler /= null);

      Handler := Event.Handler;
      Event.Handler := null;
      Handler (Event.all);

   end Execute_Handler;

   -----------------
   -- Set_Handler --
   -----------------

   procedure Set_Handler
     (Event   : in out Timing_Event;
      At_Time : Time;
      Handler : Timing_Event_Handler)
   is
   begin

      Protection.Enter_Kernel;

      Event.Handler := Handler;

      SBT.Cancel_Handler (Event.Alarm'Unrestricted_Access);

      if Handler /= null then
         SBT.Set_Handler (Event.Alarm'Unrestricted_Access,
                          SBT.Time (At_Time),
                          Execute_Handler'Access,
                          Event'Address);
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

      SBT.Cancel_Handler (Event.Alarm'Unrestricted_Access);

      Cancelled     := Event.Handler /= null;
      Event.Handler := null;

      Protection.Leave_Kernel_No_Change;

   end Cancel_Handler;

   -------------------
   -- Time_Of_Event --
   -------------------

   function Time_Of_Event (Event : Timing_Event) return Time is
   begin
      return Time (SBT.Time_Of_Alarm (Event.Alarm'Unrestricted_Access));
   end Time_Of_Event;

end Ada.Real_Time.Timing_Events;
