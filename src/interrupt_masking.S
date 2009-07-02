/****************************************************************************
 *                                                                          *
 *                GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                  *
 *                                                                          *
 *                      C P U _ O P E R A T I O N S                         *
 *                                                                          *
 *                             Assembly File                                *
 *                                                                          *
 *      Copyright (C) 1999-2002 Universidad Politecnica de Madrid           *
 *             Copyright (C) 2003-2005 The European Space Agency            *
 *                     Copyright (C) 2003-2005 AdaCore                      *
 *             Copyright (C) 2007-2008 Kristoffer N. Gregertsen             *	
 *                                                                          *
 * GNAT is free software;  you can  redistribute it  and/or modify it under *
 * terms of the  GNU General Public License as published  by the Free Soft- *
 * ware  Foundation;  either version 2,  or (at your option) any later ver- *
 * sion.  GNAT is distributed in the hope that it will be useful, but WITH- *
 * OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY *
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License *
 * for  more details.  You should have  received  a copy of the GNU General *
 * Public License  distributed with GNAT;  see file COPYING.  If not, write *
 * to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, *
 * MA 02111-1307, USA.                                                      *
 *                                                                          *
 * As a  special  exception,  if you  link  this file  with other  files to *
 * produce an executable,  this file does not by itself cause the resulting *
 * executable to be covered by the GNU General Public License. This except- *
 * ion does not  however invalidate  any other reasons  why the  executable *
 * file might be covered by the  GNU Public License.                        *
 *                                                                          *
 * GNARL was developed by the GNARL team at Florida State University.       *
 * Extensive contributions were provided by Ada Core Technologies, Inc.     *
 * The  executive  was developed  by the  Real-Time  Systems  Group  at the *
 * Technical University of Madrid.                                          *
 *                                                                          *
 ****************************************************************************/

/* This file is a AVR32 specific implementation. */

#include "avr32.h"

	.text
	.align 4

/***************************************************
 * Procedure _disable_interrupts
 ***************************************************/
	.global disable_interrupts
disable_interrupts:
	/* Disable global interrupts and return */
	ssrf 	SR_GM
	nop
	nop
	mov 	pc, lr

/***************************************************
 * Procedure _restore_interrupts 
 ***************************************************/
	.global restore_interrupts
restore_interrupts:
	/* Enable global interrupts and return */
	csrf 	SR_GM
	nop
	nop
	mov 	pc, lr
		
/***************************************************
 * Procedure enable_interrupts (interrupt_level)
 ***************************************************/
	.global enable_interrupts
enable_interrupts:
	/* Mask(3..0) equals (1 << L) - 1 */
	mov	r11, 1
	lsl	r12, r11, r12
	sub	r12, 1
	/* Global mask is 0 */
	lsl	r12, r12, 1
	/* Update system register */
	mfsr	r11, SYSREG_SR
	bfins	r11, r12, SR_GM, 5
	mtsr	SYSREG_SR, r11
	nop
	nop
	/* Return */
	mov 	pc, lr
