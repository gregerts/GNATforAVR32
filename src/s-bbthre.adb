------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                       S Y S T E M . B B . T H R E A D S                  --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
--                     Copyright (C) 2003-2007, AdaCore                     --
--             Copyright (C) 2007-2011, Kristoffer N. Gregertsen            --
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
--  Used for Storage_Offset

with System.BB.Parameters;
--  Used for Top_Of_Environment_Stack
--           Bottom_Of_Environment_Stack

with System.BB.Protection;
--  Used for Enter_Kernel
--           Leave_Kernel

with System.BB.Threads.Queues;
--  Used for Extract
--           Insert
--           Change_Priority
--           Running_Thread

with System.BB.Peripherals;
--  Used for Initialize_Board

with Ada.Unchecked_Conversion;

package body System.BB.Threads is

   use System.BB.CPU_Primitives;
   use System.BB.Time;
   use System.BB.Parameters;

   use type System.Address;
   use type System.Parameters.Size_Type;
   use type System.Storage_Elements.Storage_Offset;

   -----------------------
   -- Internal routines --
   -----------------------

   function To_Address is new Ada.Unchecked_Conversion
     (Thread_Id, System.Address);

   function To_Thread_Id is new Ada.Unchecked_Conversion
     (System.Address, Thread_Id);

   procedure Wakeup_Delayed (Thread_Addr : System.Address);
   --  Internal alarm handler used for the waking up delayed threads

   -----------------
   -- Delay_Until --
   -----------------

   procedure Delay_Until (T : System.BB.Time.Time) is
      Self_Id : constant Thread_Id := Queues.Running_Thread;
   begin
      Protection.Enter_Kernel;

      --  Test if the alarm time is in the future

      if T > Elapsed_Time (Real_Time_Clock) then

         --  Update state of thread to Delayed

         Self_Id.State := Delayed;

         --  Extract the thread from the ready queue

         Queues.Extract (Self_Id);

         --  Set alarm for waking up thread

         Set (Self_Id.Alarm'Access, T);

      else
         --  The alarm time is not in the future, yield the CPU

         Queues.Yield (Self_Id);
      end if;

      Protection.Leave_Kernel;

      --  Now the thread has been awaken again and it is executing
   end Delay_Until;

   --------------
   -- Get_ATCB --
   --------------

   function Get_ATCB return System.Address is
   begin
      return System.BB.Threads.Queues.Running_Thread.ATCB;
   end Get_ATCB;

   ------------------
   -- Get_Priority --
   ------------------

   function Get_Priority (Id : Thread_Id) return System.Any_Priority is
   begin
      --  This function does not need to be protected by Enter_Kernel and
      --  Leave_Kernel, because the Active_Priority value is only updated
      --  by Set_Priority (atomically). Moreover, Active_Priority is
      --  marked as Volatile.

      return Id.Active_Priority;
   end Get_Priority;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Environment_Thread : Thread_Id;
      Main_Priority      : System.Any_Priority)
   is
      Success : Boolean;
   begin
      --  Perform some basic hardware initialization (clock, timer, and
      --  interrupt handlers).

      Peripherals.Initialize_Board;
      Interrupts.Initialize_Interrupts;

      --  Initialize internal queues and the environment task

      Protection.Enter_Kernel;

      --  The environment thread executes the main procedure of the program

      --  The active priority is initially equal to the base priority

      Environment_Thread.Base_Priority   := Main_Priority;
      Environment_Thread.Active_Priority := Main_Priority;

      --  The currently executing thread (and the only one) is the
      --  environment thread.

      Queues.Running_Thread := Environment_Thread;
      Queues.First_Thread   := Environment_Thread;

      Environment_Thread.Next := Null_Thread_Id;

      --  Store stack information

      Environment_Thread.Top_Of_Stack := Top_Of_Environment_Stack'Address;

      Environment_Thread.Bottom_Of_Stack :=
        Bottom_Of_Environment_Stack'Address;

      --  The initial state is Runnable

      Environment_Thread.State := Runnable;

      --  No wakeup has been yet signaled

      Environment_Thread.Wakeup_Signaled := False;

      --  Initialize the timers

      Initialize_Timers (Time.Thread_Id (Environment_Thread));

      --  Initialize alarm timer

      Initialize_Alarm (Environment_Thread.Alarm'Access,
                        Real_Time_Clock,
                        Wakeup_Delayed'Access,
                        To_Address (Environment_Thread),
                        Success);

      pragma Assert (Success);

      Protection.Leave_Kernel;
   end Initialize;

   --------------
   -- Set_ATCB --
   --------------

   procedure Set_ATCB (ATCB : System.Address) is
   begin
      --  Set_ATCB is only called in the initialization of the task, and
      --  just by the owner of the thread, so there is no need of explicit
      --  kernel protection when calling this function.

      System.BB.Threads.Queues.Running_Thread.ATCB := ATCB;
   end Set_ATCB;

   ------------------
   -- Set_Priority --
   ------------------

   procedure Set_Priority (Priority  : System.Any_Priority) is
   begin
      Protection.Enter_Kernel;

      --  The Ravenscar profile does not allow dynamic priority changes. Tasks
      --  change their priority only when they inherit the ceiling priority of
      --  a PO (Ceiling Locking policy). Hence, the task must be running when
      --  changing the priority. It is not possible to change the priority of
      --  another thread within the Ravenscar profile, so that is why
      --  Running_Thread is used.

      --  Priority changes are only possible as a result of inheriting the
      --  ceiling priority of a protected object. Hence, it can never be set
      --  a priority which is lower than the base priority of the thread.

      pragma Assert (Priority >= Queues.Running_Thread.Base_Priority);

      Queues.Change_Priority (Queues.Running_Thread, Priority);

      Protection.Leave_Kernel;
   end Set_Priority;

   -----------
   -- Sleep --
   -----------

   procedure Sleep is
      Self_Id : constant Thread_Id := Queues.Running_Thread;
   begin
      Protection.Enter_Kernel;

      if Self_Id.Wakeup_Signaled then

         --  Another thread has already executed a Wakeup on this thread so
         --  that we just consume the token and continue execution.

         Self_Id.Wakeup_Signaled := False;

      else
         --  Update status

         Self_Id.State := Suspended;

         --  Extract from the list of ready threads

         Queues.Extract (Self_Id);

         --  The currently executing thread is now blocked, and it will leave
         --  the CPU when executing the Leave_Kernel procedure.

      end if;

      Protection.Leave_Kernel;

      --  Now the thread has been awaken again and it is executing
   end Sleep;

   -------------------
   -- Thread_Create --
   -------------------

   procedure Thread_Create
     (Id            : Thread_Id;
      Code          : System.Address;
      Arg           : System.Address;
      Priority      : System.Any_Priority;
      Stack_Address : System.Address;
      Stack_Size    : System.Parameters.Size_Type)
   is
      Success : Boolean;
   begin
      Protection.Enter_Kernel;

      --  Set the base and active priority

      Id.Base_Priority   := Priority;
      Id.Active_Priority := Priority;

      --  Insert task inside the ready list (as last within its priority)

      Queues.Insert (Id);

      --  Store stack information

      Id.Top_Of_Stack :=
        ((Stack_Address +
          System.Storage_Elements.Storage_Offset (Stack_Size)) /
         Standard'Maximum_Alignment) *
        Standard'Maximum_Alignment;

      Id.Bottom_Of_Stack := Stack_Address;

      --  The initial state is Runnable

      Id.State := Runnable;

      --  No wakeup has been yet signaled

      Id.Wakeup_Signaled := False;

      --  Initialize the saved registers, including the program counter and
      --  stack pointer. The thread will execute the Thread_Caller procedure
      --  and the stack pointer points to the top of the stack assigned to the
      --  thread.

      Initialize_Context (Id.Context'Access, Code, Arg, Id.Top_Of_Stack);

      --  Initialize execution time clock

      Initialize_Thread_Clock (Time.Thread_Id (Id));

      --  Initialize alarm timer

      Initialize_Alarm (Id.Alarm'Access,
                        Real_Time_Clock,
                        Wakeup_Delayed'Access,
                        To_Address (Id),
                        Success);

      pragma Assert (Success);

      Protection.Leave_Kernel;
   end Thread_Create;

   -----------------
   -- Thread_Self --
   -----------------

   function Thread_Self return Thread_Id is
   begin
      --  Return the thread that is currently executing

      return Queues.Running_Thread;
   end Thread_Self;

   ------------
   -- Wakeup --
   ------------

   procedure Wakeup (Id : Thread_Id) is
   begin
      Protection.Enter_Kernel;

      if Id.State = Suspended then

         --  The thread is already waiting so that we awake it

         Id.State := Runnable;

         --  Insert the thread at the tail of its active priority so that the
         --  thread will resume execution.

         Queues.Insert (Id);

      else
         --  The thread is not yet waiting so that we just signal that the
         --  Wakeup command has been executed.

         Id.Wakeup_Signaled := True;
      end if;

      Protection.Leave_Kernel;
   end Wakeup;

   --------------------
   -- Wakeup_Delayed --
   --------------------

   procedure Wakeup_Delayed (Thread_Addr : System.Address) is
      Id : constant Thread_Id := To_Thread_Id (Thread_Addr);
   begin
      --  We can only awake delayed tasks

      pragma Assert (Id.State = Delayed);

      Id.State := Runnable;

      Queues.Insert (Id);

   end Wakeup_Delayed;

end System.BB.Threads;
