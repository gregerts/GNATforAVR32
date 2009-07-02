------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                   A D A . I N T E R R U P T S . N A M E S                --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
--             Copyright (C) 1991-1994, Florida State University            --
--                     Copyright (C) 1995-2006, AdaCore                     --
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
------------------------------------------------------------------------------

--  This is the version for AVR32/UC3A targets of this package

with Ada.Interrupts;
--  Used for Interrupt_ID

with System.OS_Interface;
--  Used for names and priorities of interrupts

package Ada.Interrupts.Names is

   package OSI renames System.OS_Interface;

   ---------------------------
   -- Peripheral Interrupts --
   ---------------------------

   --  Group 18
   SDRAMC           : constant := OSI.SDRAMC;
   SDRAMC_Priority  : constant := OSI.SDRAMC_Priority;
   --  Group 17
   USB              : constant := OSI.USB;
   USB_Priority     : constant := OSI.USB_Priority;
   --  Group 16
   MACB             : constant := OSI.MACB;
   MACB_Priority    : constant := OSI.MACB_Priority;
   --  Group 15
   ADC              : constant := OSI.ADC;
   ADC_Priority     : constant := OSI.ADC_Priority;
   --  Group 14
   TC_2             : constant := OSI.TC_2;
   TC_2_Priority    : constant := OSI.TC_2_Priority;
   TC_1             : constant := OSI.TC_1;
   TC_1_Priority    : constant := OSI.TC_1_Priority;
   TC_0             : constant := OSI.TC_0;
   TC_0_Priority    : constant := OSI.TC_0_Priority;
   --  Group 13
   SSC              : constant := OSI.SSC;
   SSC_Priority     : constant := OSI.SSC_Priority;
   --  Group 12
   PWM              : constant := OSI.PWM;
   PWM_Priority     : constant := OSI.PWM_Priority;
   --  Group 11
   TWI              : constant := OSI.TWI;
   TWI_Priority     : constant := OSI.TWI_Priority;
   --  Group 10
   SPI_1            : constant := OSI.SPI_1;
   SPI_1_Priority   : constant := OSI.SPI_1_Priority;
   --  Group 9
   SPI_0            : constant := OSI.SPI_0;
   SPI_0_Priority   : constant := OSI.SPI_0_Priority;
   --  Group 8
   USART_3          : constant := OSI.USART_3;
   USART_3_Priority : constant := OSI.USART_3_Priority;
   --  Group 7
   USART_2          : constant := OSI.USART_2;
   USART_2_Priority : constant := OSI.USART_2_Priority;
   --  Group 6
   USART_1          : constant := OSI.USART_1;
   USART_1_Priority : constant := OSI.USART_1_Priority;
   --  Group 5
   USART_0          : constant := OSI.USART_0;
   USART_0_Priority : constant := OSI.USART_0_Priority;
   --  Group 4
   FLASHC           : constant := OSI.FLASHC;
   FLASHC_Priority  : constant := OSI.FLASHC_Priority;
   --  Group 3
   PDCA_14          : constant := OSI.PDCA_14;
   PDCA_14_Priority : constant := OSI.PDCA_14_Priority;
   PDCA_13          : constant := OSI.PDCA_13;
   PDCA_13_Priority : constant := OSI.PDCA_13_Priority;
   PDCA_12          : constant := OSI.PDCA_12;
   PDCA_12_Priority : constant := OSI.PDCA_12_Priority;
   PDCA_11          : constant := OSI.PDCA_11;
   PDCA_11_Priority : constant := OSI.PDCA_11_Priority;
   PDCA_10          : constant := OSI.PDCA_10;
   PDCA_10_Priority : constant := OSI.PDCA_10_Priority;
   PDCA_9           : constant := OSI.PDCA_9;
   PDCA_9_Priority  : constant := OSI.PDCA_9_Priority;
   PDCA_8           : constant := OSI.PDCA_8;
   PDCA_8_Priority  : constant := OSI.PDCA_8_Priority;
   PDCA_7           : constant := OSI.PDCA_7;
   PDCA_7_Priority  : constant := OSI.PDCA_7_Priority;
   PDCA_6           : constant := OSI.PDCA_6;
   PDCA_6_Priority  : constant := OSI.PDCA_6_Priority;
   PDCA_5           : constant := OSI.PDCA_5;
   PDCA_5_Priority  : constant := OSI.PDCA_5_Priority;
   PDCA_4           : constant := OSI.PDCA_4;
   PDCA_4_Priority  : constant := OSI.PDCA_4_Priority;
   PDCA_3           : constant := OSI.PDCA_3;
   PDCA_3_Priority  : constant := OSI.PDCA_3_Priority;
   PDCA_2           : constant := OSI.PDCA_2;
   PDCA_2_Priority  : constant := OSI.PDCA_2_Priority;
   PDCA_1           : constant := OSI.PDCA_1;
   PDCA_1_Priority  : constant := OSI.PDCA_1_Priority;
   PDCA_0           : constant := OSI.PDCA_0;
   PDCA_0_Priority  : constant := OSI.PDCA_0_Priority;
   --  Group 2
   GPIO_13          : constant := OSI.GPIO_13;
   GPIO_13_Priority : constant := OSI.GPIO_13_Priority;
   GPIO_12          : constant := OSI.GPIO_12;
   GPIO_12_Priority : constant := OSI.GPIO_12_Priority;
   GPIO_11          : constant := OSI.GPIO_11;
   GPIO_11_Priority : constant := OSI.GPIO_11_Priority;
   GPIO_10          : constant := OSI.GPIO_10;
   GPIO_10_Priority : constant := OSI.GPIO_10_Priority;
   GPIO_9           : constant := OSI.GPIO_9;
   GPIO_9_Priority  : constant := OSI.GPIO_9_Priority;
   GPIO_8           : constant := OSI.GPIO_8;
   GPIO_8_Priority  : constant := OSI.GPIO_8_Priority;
   GPIO_7           : constant := OSI.GPIO_7;
   GPIO_7_Priority  : constant := OSI.GPIO_7_Priority;
   GPIO_6           : constant := OSI.GPIO_6;
   GPIO_6_Priority  : constant := OSI.GPIO_6_Priority;
   GPIO_5           : constant := OSI.GPIO_5;
   GPIO_5_Priority  : constant := OSI.GPIO_5_Priority;
   GPIO_4           : constant := OSI.GPIO_4;
   GPIO_4_Priority  : constant := OSI.GPIO_4_Priority;
   GPIO_3           : constant := OSI.GPIO_3;
   GPIO_3_Priority  : constant := OSI.GPIO_3_Priority;
   GPIO_2           : constant := OSI.GPIO_2;
   GPIO_2_Priority  : constant := OSI.GPIO_2_Priority;
   GPIO_1           : constant := OSI.GPIO_1;
   GPIO_1_Priority  : constant := OSI.GPIO_1_Priority;
   GPIO_0           : constant := OSI.GPIO_0;
   GPIO_0_Priority  : constant := OSI.GPIO_0_Priority;
   --  Group 1
   FREQM            : constant := OSI.FREQM;
   FREQM_Priority   : constant := OSI.FREQM_Priority;
   PM               : constant := OSI.PM;
   PM_Priority      : constant := OSI.PM_Priority;
   RTC              : constant := OSI.RTC;
   RTC_Priority     : constant := OSI.RTC_Priority;
   EIM_7            : constant := OSI.EIM_7;
   EIM_7_Priority   : constant := OSI.EIM_7_Priority;
   EIM_6            : constant := OSI.EIM_6;
   EIM_6_Priority   : constant := OSI.EIM_6_Priority;
   EIM_5            : constant := OSI.EIM_5;
   EIM_5_Priority   : constant := OSI.EIM_5_Priority;
   EIM_4            : constant := OSI.EIM_4;
   EIM_4_Priority   : constant := OSI.EIM_4_Priority;
   EIM_3            : constant := OSI.EIM_3;
   EIM_3_Priority   : constant := OSI.EIM_3_Priority;
   EIM_2            : constant := OSI.EIM_2;
   EIM_2_Priority   : constant := OSI.EIM_2_Priority;
   EIM_1            : constant := OSI.EIM_1;
   EIM_1_Priority   : constant := OSI.EIM_1_Priority;
   EIM_0            : constant := OSI.EIM_0;
   EIM_0_Priority   : constant := OSI.EIM_0_Priority;
   --  Group 0
   COMPARE          : constant := OSI.COMPARE;
   COMPARE_Priority : constant := OSI.COMPARE_Priority;

end Ada.Interrupts.Names;
