/****************************************************************************
 *									    *
 *		  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS		    *
 *									    *
 *		      E X C E P T I O N _ H A N D L E R			    *
 *									    *
 *				 Assembly File				    *
 *									    *
 *	       Copyright (C) 2007-2008 Kristoffer N. Gregertsen		    *
 *									    *
 * GNAT is free software;  you can  redistribute it  and/or modify it under *
 * terms of the	 GNU General Public License as published  by the Free Soft- *
 * ware	 Foundation;  either version 2,	 or (at your option) any later ver- *
 * sion.  GNAT is distributed in the hope that it will be useful, but WITH- *
 * OUT ANY WARRANTY;  without even the	implied warranty of MERCHANTABILITY *
 * or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU General Public License *
 * for	more details.  You should have	received  a copy of the GNU General *
 * Public License  distributed with GNAT;  see file COPYING.  If not, write *
 * to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, *
 * MA 02111-1307, USA.							    *
 *									    *
 * As a	 special  exception,  if you  link  this file  with other  files to *
 * produce an executable,  this file does not by itself cause the resulting *
 * executable to be covered by the GNU General Public License. This except- *
 * ion does not	 however invalidate  any other reasons	why the	 executable *
 * file might be covered by the	 GNU Public License.			    *
 *									    *
 * GNARL was developed by the GNARL team at Florida State University.	    *
 * Extensive contributions were provided by Ada Core Technologies, Inc.	    *
 * The	executive  was developed  by the  Real-Time  Systems  Group  at the *
 * Technical University of Madrid.					    *
 *									    *
 ****************************************************************************/

#include "avr32.h"

.macro EXCEPTION_HANDLER offset
	.org  \offset
	rjmp	$
.endm

.macro INTERRUPT_HANDLER level

	/* Set global interrupt mask */
	ssrf	SR_GM
	nop
	nop

	/* Load stack pointer for interrupt level from stack table */
	lda.w	r8, interrupt_stack_table
	mov 	r9, sp
	ld.w	sp, r8[4 * \level]

	/* Push task stack pointer on interrupt stack */
	st.w	--sp, r9

	/* Call interrupt_wrapper (level) */
	mov	r12, \level
	call	interrupt_wrapper

	/* Pop task stack pointer from interrupt stack */
	ld.w	r9, sp++
	mov	sp, r9

	/* Preform context switch if needed */
	call	context_switch_needed
	cp.w	r12, 0
	breq	0f
	call	context_switch
0:	
	rete
.endm

	.section .exception, "ax", @progbits

/*************************************************************
 * Start of Exception Vector Table.
 *
 *  EVBA must be aligned with a power of two strictly greater
 *  than the EVBA-relative offset of the last vector.
 *************************************************************/
	.balign 0x200

	/* Export symbol */
	.global _evba
	.type _evba, @function
_evba:

	/* Unrecoverable exception */
	EXCEPTION_HANDLER 0x000

	/* TLB Multiple Hit */
	EXCEPTION_HANDLER 0x004

	/* Bus Error Data Fetch */
	EXCEPTION_HANDLER 0x008

	 /* Bus Error Instruction Fetch */
	EXCEPTION_HANDLER 0x00C

	/* NMI */
	EXCEPTION_HANDLER 0x010

	/* Instruction Address */
	EXCEPTION_HANDLER 0x014

	/* ITLB Protection */
	EXCEPTION_HANDLER 0x018

	/* Breakpoint */
	EXCEPTION_HANDLER 0x01C

	/* Illegal Opcode */
	EXCEPTION_HANDLER 0x020

	/* Unimplemented Instruction */
	EXCEPTION_HANDLER 0x024

	/* Privilege Violation */
	EXCEPTION_HANDLER 0x028

	/* Floating-Point */
	EXCEPTION_HANDLER 0x02C

	/* Coprocessor Absent */
	EXCEPTION_HANDLER 0x030

	/* Data Address (Read) */
	EXCEPTION_HANDLER 0x034

	/* Data Address (Write) */
	EXCEPTION_HANDLER 0x038

	/* DTLB Protection (Read) */
	EXCEPTION_HANDLER 0x03C

	/* DTLB Protection (Write) */
	EXCEPTION_HANDLER 0x040

	/* DTLB Modified */
	EXCEPTION_HANDLER 0x044

	/* ITLB Miss */
	EXCEPTION_HANDLER 0x050

	/* DTLB Miss (Read) */
	EXCEPTION_HANDLER 0x060

	/* DTLB Miss (Write) */
	EXCEPTION_HANDLER 0x070

	/* Supervisor Call */
	EXCEPTION_HANDLER 0x100

/*************************************************************
 * Interrupt Handlers
 *************************************************************/
	.balign 4

_int_0:
	INTERRUPT_HANDLER 1

_int_1:
	INTERRUPT_HANDLER 2

_int_2:
	INTERRUPT_HANDLER 3

_int_3:
	INTERRUPT_HANDLER 4

/*************************************************************
 * Interrupt autovectors
 *************************************************************/
	.balign 4

	.global autovectors
	.type autovectors, @object
autovectors:
	.word	0,\
		(_int_0 - _evba),\
		(_int_1 - _evba),\
		(_int_2 - _evba),\
		(_int_3 - _evba)
