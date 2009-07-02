------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                     S Y S T E M . B B . M E M O R Y                      --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--              Copyright (C) 2009, Kristoffer Nyborg Gregertsen            --
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

--  This package provides the low level memory allocation/deallocation
--  mechanisms used by GNAT.

package System.Memory is

   pragma Elaborate_Body;

   type size_t is mod 2 ** Standard'Address_Size;
   --  Note: the reason we redefine this here instead of using the
   --  definition in Interfaces.C is that we do not want to drag in
   --  all of Interfaces.C just because System.Memory is used.

   function Alloc (Size : size_t) return System.Address;
   --  This is the low level allocation routine. Given a size in storage
   --  units, it returns the address of a maximally aligned block of
   --  memory. The implementation of this routine is guaranteed to be
   --  task safe.
   --
   --  If size_t is set to size_t'Last on entry, then a Storage_Error
   --  exception is raised.
   --
   --  If size_t is set to zero on entry, then a minimal (but non-zero)
   --  size block is allocated.

private

   --  The following names are used from the generated compiler code

   pragma Export (C, Alloc,   "__gnat_malloc");

end System.Memory;
