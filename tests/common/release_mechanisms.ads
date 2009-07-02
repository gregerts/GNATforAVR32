------------------------------------------------------------------
--  Adapted from "Concurrent and Real-Time Programming in Ada"  --
--               by Alan Burns and Andy Wellings.               --
------------------------------------------------------------------

package Release_Mechanisms is

   type Release_Mechanism is limited interface;

   procedure Wait_For_Next_Release (R : in out Release_Mechanism) is abstract;

   type Any_Release_Mechanism is access all Release_Mechanism'Class;

   type Open_Release_Mechanism is
      limited interface and Release_Mechanism;

   procedure Release (R : in out Open_Release_Mechanism)
      is abstract;

   type Any_Open_Release_Mechanism
      is access all Open_Release_Mechanism'Class;

end Release_Mechanisms;
