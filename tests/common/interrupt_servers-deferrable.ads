with Ada.Task_Identification, Ada.Execution_Time.Timers,
  Ada.Execution_Time.Interrupts.Timers, Ada.Real_Time.Timing_Events,
  Epoch_Support, System;
use Ada.Task_Identification, Ada.Execution_Time.Timers,
  Ada.Execution_Time.Interrupts.Timers, Ada.Real_Time.Timing_Events,
  Epoch_Support, System;

package Interrupt_Servers.Deferrable is

   type Deferrable_Interrupt_Server
     (Param : access Interrupt_Server_Parameters) is
      limited new Interrupt_Server with private;

   procedure Initialize (S : in out Deferrable_Interrupt_Server);

private

   protected type Mechanism (Param : access Interrupt_Server_Parameters) is

      procedure Initialize;

      pragma Priority (Any_Priority'Last);

   private

      procedure Replenish (Event : in out Timing_Event);

      procedure Overrun (TM : in out Timer);

      Replenish_Event : Timing_Event;
      Execution_Timer : access Interrupt_Timer;

      Next : Time;

      Disabled : Boolean := True;
      State : Any_Interrupt_State := null;

   end Mechanism;

   type Deferrable_Interrupt_Server
     (Param : access Interrupt_Server_Parameters) is
      limited new Interrupt_Server with
      record
         M : Mechanism (Param);
      end record;

end Interrupt_Servers.Deferrable;
