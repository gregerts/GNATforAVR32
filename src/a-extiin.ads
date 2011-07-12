------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--        A D A . E X E C U T I O N _ T I M E . I N T E R R U P T S         --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--             Copyright (C) 2010-2011, Kristoffer N. Gregertsen            --
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

--  This is the Ravenscar version of this package for AVR32 bare board

with Ada.Interrupts;

package Ada.Execution_Time.Interrupts is

   function Clock (I : Ada.Interrupts.Interrupt_ID) return CPU_Time;

   function Supported (I : Ada.Interrupts.Interrupt_ID) return Boolean;

private

   pragma Inline (Clock);
   pragma Inline (Supported);

end Ada.Execution_Time.Interrupts;
