------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                   S Y S T E M . B B . I N T E R R U P T S                --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
--                     Copyright (C) 2003-2007, AdaCore                     --
--             Copyright (C) 2007-2008 Kristoffer N. Gregertsen             --
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

pragma Restrictions (No_Elaboration_Code);

with System.Storage_Elements;
--  used for Storage_Array
--           Storage_Offset

with System.BB.CPU_Primitives;
--  Used for Enable_Interrupts
--           Disable_Interrupts
--           Restore_Interrupts

with System.BB.Threads;
--  Used for Thread_Self
--           Get_Priority

with System.BB.Threads.Queues;
--  Used for Change_Priority

with System.BB.Peripherals;
--  Used for To_Level

with System.BB.Time;
--  Used for Enter_Interrupt
--           Leave_Interrupt

package body System.BB.Interrupts is

   package SSE renames System.Storage_Elements;

   use type System.Storage_Elements.Storage_Offset;

   ----------------
   -- Local data --
   ----------------

   type Stack_Space is new SSE.Storage_Array
     (1 .. SSE.Storage_Offset (Parameters.Interrupt_Stack_Size));
   for Stack_Space'Alignment use 8;
   --  Type used to represent the stack area for each interrupt. The
   --  stack must be aligned to 8 bytes to allow double word data
   --  movements.

   Interrupt_Stacks : array (Interrupt_Level) of Stack_Space;
   --  Array that contains the stack used for each interrupt level.

   Interrupt_Stack_Table : array (Interrupt_Level) of System.Address;
   pragma Export (Asm, Interrupt_Stack_Table, "interrupt_stack_table");
   --  Table that contains a pointer to the top of the stack for each
   --  interrupt.

   type Handlers_Table is array (Interrupt_ID) of Interrupt_Handler;
   pragma Suppress_Initialization (Handlers_Table);
   --  Type used to represent the procedures used as interrupt
   --  handlers.

   Interrupt_Handlers_Table : Handlers_Table;
   --  Table containing handlers attached to the different external
   --  interrupts.

   Interrupt_Being_Handled : Interrupt_ID := No_Interrupt;
   pragma Atomic (Interrupt_Being_Handled);
   --  Interrupt_Being_Handled contains the interrupt currently being
   --  handled in the system. It is equal to 0 when no interrupt is
   --  handled. Its value is updated by the trap handler.

   -----------------------
   -- Local subprograms --
   -----------------------

   procedure Interrupt_Wrapper
     (Interrupt : Interrupt_ID;
      Level     : Interrupt_Level);
   pragma Export (Asm, Interrupt_Wrapper, "interrupt_wrapper");
   --  This wrapper procedure is in charge of setting the appropriate
   --  software priorities before calling the user-defined handler.

   --------------------
   -- Attach_Handler --
   --------------------

   procedure Attach_Handler
     (Handler : Interrupt_Handler;
      Id      : Interrupt_ID)
   is
   begin
      --  Check that we are attaching to a real interrupt

      pragma Assert (Id /= No_Interrupt);

      --  Copy the user's handler to the appropriate place within the table

      Interrupt_Handlers_Table (Id) := Handler;

      Time.Initialize_Interrupt_Clock (Id);

   end Attach_Handler;

   ---------------------------
   -- Priority_Of_Interrupt --
   ---------------------------

   function Priority_Of_Interrupt
     (Id : Interrupt_ID) return System.Any_Priority
   is
   begin
      --  Assert that it is a real interrupt.
      pragma Assert (Id /= No_Interrupt);

      return To_Priority (Peripherals.To_Level (Id));
   end Priority_Of_Interrupt;

   -----------------
   -- To_Priority --
   -----------------

   function To_Priority
     (Level : Interrupt_Level) return System.Any_Priority
   is
   begin
      return Interrupt_Priority'First + Any_Priority (Level);
   end To_Priority;

   -----------------------
   -- Current_Interrupt --
   -----------------------

   function Current_Interrupt return Interrupt_ID is
   begin
      return Interrupt_Being_Handled;
   end Current_Interrupt;

   -----------------------
   -- Interrupt_Wrapper --
   -----------------------

   procedure Interrupt_Wrapper
     (Interrupt : Interrupt_ID;
      Level     : Interrupt_Level)
   is

      Self_Id : constant Threads.Thread_Id :=
        Threads.Thread_Self;

      Caller_Priority : constant Any_Priority :=
        Threads.Get_Priority (Self_Id);

      Previous_Interrupt : constant Interrupt_ID :=
        Interrupt_Being_Handled;

   begin
      --  This must be an external interrupt
      pragma Assert (Level > 0);

      --  Return if no handler is registered for this interrupt
      if Interrupt_Handlers_Table (Interrupt) = null then
         return;
      end if;

      --  Change to interrupt clock
      Time.Enter_Interrupt (Interrupt);

      --  Store the interrupt being handled.
      Interrupt_Being_Handled := Interrupt;

      --  Then, we must set the appropriate software priority
      --  corresponding to the interrupt being handled. It comprises
      --  also the appropriate interrupt masking.
      Threads.Queues.Change_Priority (Self_Id, To_Priority (Level));

      --  Restore interrupts priort to calling handler
      CPU_Primitives.Restore_Interrupts;

      --  Call the user handler
      Interrupt_Handlers_Table (Interrupt).all (Interrupt);

      --  Restore interrupts
      CPU_Primitives.Disable_Interrupts;

      --  Restore the software priority to the state before the
      --  interrupt. Interrupts are enabled by context switch or by
      --  returning to normal execution.
      Threads.Queues.Change_Priority (Self_Id, Caller_Priority);

      --  Restore the interrupt that was previously handled.
      Interrupt_Being_Handled := Previous_Interrupt;

      --  Restore previous clock
      Time.Leave_Interrupt;

   end Interrupt_Wrapper;

   ----------------------------
   -- Within_Interrupt_Stack --
   ----------------------------

   function Within_Interrupt_Stack
     (Stack_Address : System.Address) return Boolean
   is
      Level : constant Interrupt_Level
        := Peripherals.To_Level (Current_Interrupt);
      Stack_Start : System.Address;
      Stack_End   : System.Address;

   begin
      if Current_Interrupt = No_Interrupt then

         --  Return False if no interrupt is being handled

         return False;
      else
         --  Calculate stack boundaries for the interrupt being handled

         Stack_Start :=
           Interrupt_Stacks (Level)(Stack_Space'First)'Address;
         Stack_End   :=
           Interrupt_Stacks (Level)(Stack_Space'Last)'Address;

         --  Compare the Address passed as argument against the
         --  previously calculated stack boundaries.

         return Stack_Address >= Stack_Start
           and then Stack_Address <= Stack_End;
      end if;

   end Within_Interrupt_Stack;

   ---------------------------
   -- Initialize_Interrupts --
   ---------------------------

   procedure Initialize_Interrupts is
   begin

      --  Level 0 has no interrupt stack
      Interrupt_Stack_Table (0) := SSE.To_Address (0);

      --  Set SP of interrupt level to the last double word
      for Index in Interrupt_Level loop
         Interrupt_Stack_Table (Index) :=
           Interrupt_Stacks (Index)(Stack_Space'Last - 7)'Address;
      end loop;

   end Initialize_Interrupts;

end System.BB.Interrupts;
