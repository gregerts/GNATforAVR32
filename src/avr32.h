#ifndef __AVR32_H
#define __AVR32_H

#define EXECUTION_TIMING

/* Context buffer offsets */
#define CONTEXT_OFFSET	  0
#define TIMER_OFFSET      48

/* System registers */
#define SYSREG_SR	  0
#define SYSREG_EVBA	  4
#define SYSREG_ACBA	  8
#define SYSREG_CPUCR	 12
#define SYSREG_ECR       16
#define SYSREG_RSR_SUP	 20
#define SYSREG_RSR_INT0	 24
#define SYSREG_RSR_INT1	 28
#define SYSREG_RSR_INT2	 32
#define SYSREG_RSR_INT3	 36
#define SYSREG_RSR_EX	 40
#define SYSREG_RSR_NMI	 44
#define SYSREG_RSR_DBG	 48
#define SYSREG_RAR_SUP	 52
#define SYSREG_RAR_INT0	 56
#define SYSREG_RAR_INT1	 60
#define SYSREG_RAR_INT2	 64
#define SYSREG_RAR_INT3	 68
#define SYSREG_RAR_EX	 72
#define SYSREG_RAR_NMI	 76
#define SYSREG_RAR_DBG	 80
#define SYSREG_JECR       84
#define SYSREG_JOSP       88
#define SYSREG_JAVA_LV0   92
#define SYSREG_JAVA_LV1   96
#define SYSREG_JAVA_LV2   100
#define SYSREG_JAVA_LV3   104
#define SYSREG_JAVA_LV4   108
#define SYSREG_JAVA_LV5   112
#define SYSREG_JAVA_LV6   116
#define SYSREG_JAVA_LV7   120
#define SYSREG_JTBA       124
#define SYSREG_JBCR       128

#define SYSREG_CONFIG0	256
#define SYSREG_CONFIG1	260
#define SYSREG_COUNT	264
#define SYSREG_COMPARE	268

#define SYSREG_BEAR 316

/* MMU interface registers */
#define SYSREG_TLBEHI	272
#define SYSREG_TLBELO	276
#define SYSREG_PTBR	280
#define SYSREG_TLBEAR	284
#define SYSREG_MMUCR	288
#define SYSREG_TLBARLO	292
#define SYSREG_TLBDRLO	296
#define SYSREG_TLBARHI	300
#define SYSREG_TLBDRHI	304

/* Performance counter */
#define SYSREG_PCCR	320

/* Status register bits */
#define SR_C    0
#define SR_Z    1
#define SR_N    2
#define SR_V    3
#define SR_Q    4
#define SR_GM   16
#define SR_I0M  17
#define SR_I1M  18
#define SR_I2M  19
#define SR_I3M  20
#define SR_EM   21
#define SR_M0   22
#define SR_M1   23
#define SR_M2   24
#define SR_D    26
#define SR_DM   27
#define SR_J    28
#define SR_R    29

/* PCCR bits */
#define PCCRS  	3
#define PCCRC  	2
#define PCCRR  	1
#define PCCRE  	0
#define PCCNT_PRESCALE 64

/* TLBEHI bits */
#define TLBEHIVPN 10
#define TLBEHIV   9
#define TLBEHII   0
 
/* TLBELO = bits */
#define TLBELOPFN 10
#define TLBELOC   9
#define TLBELOG   8
#define TLBELOB   7
#define TLBELOAP  5
#define TLBELOSZ  2
#define TLBELOD   1
#define TLBELOW   0
 
/* MMUCR bits */
#define MMUIRP	26
#define MMUILA  20
#define MMUDRP  14
#define MMUDLA  8
#define MMUS  	4
#define MMUN  	3
#define MMUI  	2
#define MMUM  	1
#define MMUE  	0
 
/* Relative offsets to EVBA */
#define H_UNREC_EX  	0x000
#define H_TLB_MH    	0x004
#define H_BUS_ERR_D 	0x008
#define H_BUS_ERR_I 	0x00C
#define H_NMI       	0x010
#define H_INST_ADDR 	0x014
#define H_ITLB_MISS 	0x050
#define H_ITLB_PROT 	0x018
#define H_DEBUG     	0x01C
#define H_ILL_OPC   	0x020
#define H_UNIMPL_INST 	0x024
#define H_PRIV_VIOL 	0x028
#define H_FLOAT_PT  	0x02C
#define H_COPROC_ABS 	0x030
#define H_SCALL  	0x100
#define H_DATA_ADDR_R  	0x034
#define H_DATA_ADDR_W  	0x038
#define H_DTLB_MISS_R  	0x060
#define H_DTLB_MISS_W  	0x070
#define H_DTLB_PROT_R  	0x03C
#define H_DTLB_PROT_W  	0x040
#define H_DTLB_MOD  	0x044

/* Interrupt levels */
#define INT_0		0
#define INT_1		1
#define INT_2		2
#define INT_3		3

/* Interrupt Controller address */
#define INT_CONTROLLER	0xFFFF0800

/* Interrupt Priority Register */
#define INT_PRIORITY	0
#define INT_LEVEL	30
#define INT_OFFSET	0
#define INT_OFFSET_BITS	24

/* Interrupt Request Register */
#define INT_REQUEST	256

/* Interrupt Cause Register */
#define INT_CAUSE	512
#define INT_CAUSE_MASK	0x3f

#endif /* ___AVR32_H */
