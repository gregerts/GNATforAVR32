------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--               S Y S T E M . B B . T H R E A D S . Q U E U E S            --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2004 The European Space Agency            --
--                     Copyright (C) 2003-2007, AdaCore                     --
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

package System.BB.Threads.Queues is
   pragma Preelaborate;

   ----------------
   -- Ready list --
   ----------------

   procedure Insert (Thread : Thread_Id);
   pragma Inline (Insert);
   --  Insert the thread into the ready queue. The thread is always
   --  inserted at the tail of its active priority because these are
   --  the semantics of FIFO_Within_Priorities dispatching policy when
   --  a task becomes ready to execute.

   procedure Extract (Thread : Thread_Id);
   pragma Inline (Extract);
   --  Remove the thread from the ready queue

   procedure Change_Priority
     (Thread   : Thread_Id;
      Priority : System.Any_Priority);
   pragma Inline (Change_Priority);
   --  Move the thread to a new priority within the ready queue

   procedure Yield (Thread : Thread_Id);
   --  Move the thread to the tail of its current priority

   Running_Thread : Thread_Id := Null_Thread_Id;
   pragma Volatile (Running_Thread);
   pragma Export (Asm, Running_Thread, "running_thread");
   --  Identifier of the thread that is currently executing in the
   --  CPU. This shared variable is used by the debugger to know which is
   --  the currently running thread. This variable is exported to be
   --  visible in the assembly code to allow its value to be used when
   --  necessary (by the low-level routines).

   First_Thread : Thread_Id := Null_Thread_Id;
   pragma Volatile (First_Thread);
   pragma Export (Asm, First_Thread, "first_thread");
   --  Pointer to the first thread of the priority queue. This is the thread
   --  that will be next to execute in the CPU (if not already executing).
   --  This variable is exported to be visible in the assembly code to allow
   --  its value to be used when necessary (by the low-level routines).

end System.BB.Threads.Queues;
