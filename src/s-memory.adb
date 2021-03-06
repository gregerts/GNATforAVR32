------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                         S Y S T E M . M E M O R Y                        --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--          Copyright (C) 2001-2008, Free Software Foundation, Inc.         --
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

--  This is the simplified implementation of this package, for use with a
--  configurable run-time library.

--  This implementation assumes that the underlying malloc/free/realloc
--  implementation is *not* thread safe, and thus, explicit lock is required.

with Ada.Exceptions;
with System.BB.Protection;

package body System.Memory is

   use Ada.Exceptions;

   function c_malloc (Size : size_t) return System.Address;
   pragma Import (C, c_malloc, "malloc");

   -----------
   -- Alloc --
   -----------

   function Alloc (Size : size_t) return System.Address is
      Result : System.Address;
   begin

      if Size = size_t'Last then
         Raise_Exception (Storage_Error'Identity);
      end if;

      System.BB.Protection.Enter_Kernel;

      Result := c_malloc (size_t'Max (Size, 1));

      System.BB.Protection.Leave_Kernel_No_Change;

      if Result = System.Null_Address then
         Raise_Exception (Storage_Error'Identity);
      end if;

      return Result;

   end Alloc;

end System.Memory;
