/****************************************************************************
 *                                                                          *
 *                GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                  *
 *                                                                          *
 *                            A D A _ C R T 0                               *
 *                                                                          *
 *                             Assembly File                                *
 *                                                                          *
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

	/* This file is mostly copied from the Newlib crt0.S */
	
#include "avr32.h"

	/* This must be linked @ 0x80000000 to be run upon reset */
	.section  .reset, "ax", @progbits
	.global _start
	.type _start, @function

_start:
	/* For some reason these four nops are needed to avoid a
	 * mismatch between the LMA and VMA of the text section.
	 *
	 * This is a bug that needs to be sorted out! */
	nop
	nop
	nop
	nop

	/* Jump to the BB runtime startup routine. */
	lda.w   pc, _stext
	.text
	.align 4

	/* _stext is placed outside the .reset section so that the
	 * program entry point an be changed without affecting the
	 * BB runtime startup. */

	.section  .text._stext, "ax", @progbits
	.global _stext
	.type _stext, @function

_stext:
	/* Set the stack for the main program */
	lda.w	sp, _estack

	/* Set up EVBA so interrupts can be enabled */
	lda.w   r0, _evba
	mtsr    SYSREG_EVBA, r0

	/* Enable the exception processing */
	csrf    SR_EM

	/* Load initialized data from the data LMA */
	lda.w   r0, _data
	lda.w   r1, _edata
	cp      r0, r1
	brhs    idata_load_loop_end
	lda.w   r2, _data_lma
idata_load_loop:
	ld.d    r4, r2++
	st.d    r0++, r4
	cp      r0, r1
	brlo    idata_load_loop
idata_load_loop_end:

	/* Set r2, r3 r4, r5 to zero */
	mov 	r2, 0
	mov	r3, r2
	mov	r4, r2
	mov	r5, r2

        /* Clear uninitialized in the bss section */
	lda.w   r0, __bss_start
	lda.w   r1, _end
	cp      r0, r1
	brhs    bss_clear_loop_end
bss_clear_loop:
	st.d    r0++, r2
	cp      r0, r1
	brlo    bss_clear_loop
bss_clear_loop_end:

	/* Set r0 and r1 to zero */
	mov 	r0, r2
	mov	r1, r2

	/* Done for safty, main should never return */
	lda.w   lr, _exit

	/* Make room for args and call the main routine */
	sub	sp, 0x80
	lda.w   pc, main

	.global	_exit
_exit:
	rjmp	_exit
	
