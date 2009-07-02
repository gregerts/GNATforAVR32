------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--    S Y S T E M . S E C O N D A R Y _ S T A C K . S I N G L E _ T A S K   --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--             Copyright (C) 2005 Free Software Foundation, Inc.            --
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

--  This package provides a default and simple implementation of a function
--  that returns a pointer to a secondary stack. This function is intended
--  to be used on single-threaded applications. Multi-threaded applications
--  require thread-local data.
--
--  The function defined in this package is used when the two following
--  conditions are met:
--    1) No user-defined implementation has been provided. That is, the
--       symbol __gnat_get_sec_stack is not exported by the user's code.
--    2) No tasking is used. When tasking is used, the __gnat_get_sec_stack
--       reference is resolved by libgnarl.a (that contains a thread-safe
--       implementation of the secondary stack), so that the single-threaded
--       version is not included in the final executable.
--
--  Note that the problem of providing different implementations for tasking
--  and not tasking applications is usually solved by using the
--  System.Soft_Links mechanism. This approach has not been followed because
--  this mechanism if it not available for the High Integrity Ravenscar run
--  times.
--
--  Another possibility would be to always use the tasking (multi-threaded)
--  version of this function. However, it forces a dependency on libgnarl in
--  libgnat, which is not desirable.

pragma Restrictions (No_Elaboration_Code);
--  We want to guarantee the absence of elaboration code because the
--  binder does not handle references to this package.

package System.Secondary_Stack.Single_Task is

   function Get_Sec_Stack return Address;
   pragma Export (C, Get_Sec_Stack, "__gnat_get_secondary_stack");
   --  Return the address of the secondary stack to be used for
   --  single-threaded applications, as expected by
   --  System.Secondary_Stack.

end System.Secondary_Stack.Single_Task;
