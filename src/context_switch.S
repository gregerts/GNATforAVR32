/****************************************************************************
 *                                                                          *
 *                GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                  *
 *                                                                          *
 *                      C O N T E X T _ S W I T C H                         *
 *                                                                          *
 *                              Assembly File                               *
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

/* This file is a AVR32 specific implementation, inspired by AVR32 Linux  */

#include "avr32.h"

/* Procedure: context_switch
 *
 * This routine performs a context switch between the two tasks that are
 * specified in running_thread and first_thread.
 *
 * Task context is stored in the order R12, PC, SR, R0, R1 .. R7
 */

	.text
	.align 4

	.global context_switch
	.type	context_switch, @function

context_switch:

	/* Store address of running thread in r9 */
	lda.w	r8, running_thread
	ld.w	r9, r8

	/* Add size of context */
	sub	r9, -CONTEXT_SIZE

	/* Save CPU context of running thread */
	stm	--r9, r0,r1,r2,r3,r4,r5,r6,r7,sp,lr
	mfsr	r0, SYSREG_SR
	st.w	--r9, r0

	/* Store address of first thread in r1 */
	lda.w	r1, first_thread
	ld.w	r9, r1

	/* First thread is now also running thread */
	st.w	r8, r2

	/* Load context of first thread */
	mov	r9, r2
	ld.w	r0, r9++
	mtsr	SYSREG_SR, r0
	sub	pc, -2
	ldm	r9++, r0,r1,r2,r3,r4,r5,r6,r7,sp,pc
