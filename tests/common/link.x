/* Default linker script, for normal executables */

OUTPUT_FORMAT("elf32-avr32", "elf32-avr32", "elf32-avr32")
OUTPUT_ARCH(avr32:uc)
ENTRY(_start)
SEARCH_DIR("/usr/avr32/lib");

MEMORY
  {
    FLASH (rxai!w)  : ORIGIN = 0x80000000, LENGTH = 512K
    INTRAM (wxa!ri) : ORIGIN = 0x00000000, LENGTH = 64K
    USERPAGE        : ORIGIN = 0x80800000, LENGTH = 512
    FACTORYPAGE     : ORIGIN = 0x80800200, LENGTH = 512
  }

SECTIONS
{
  /* Text sections */

  .reset    : {  *(.reset) } >FLASH AT>FLASH
  .rela.got : { *(.rela.got) } >FLASH AT>FLASH

  .text :
  {
	*(.exception);
	s-*(.text .stub .text.*);
	a-*(.text .stub .text.*);
	g-*(.text .stub .text.*);
	*(.text .stub .text.*);
	. = ALIGN (256);
  } >FLASH AT>FLASH =0xd703d703

  /* Error handling (?) frame */
  
  .eh_frame : { KEEP (*(.eh_frame)) } >FLASH AT>FLASH
  .dalign   : { . = ALIGN(8); _data_lma = .; } >FLASH AT>FLASH

  /* Data in memory */

  . = ORIGIN(INTRAM);
  .eh_frame : { KEEP (*(.eh_frame)) } >INTRAM AT>FLASH
  .data	    :
  {
	. = ALIGN(8);
	_data = .;
    	s-*(.data .data.*)
    	a-*(.data .data.*)
    	g-*(.data .data.*)
    	*(.data .data.*)
  } >INTRAM AT>FLASH
  .balign   : { . = ALIGN(8); _edata = .; } >INTRAM AT>FLASH
  _edata = .;

  /* BSS in memory */

  __bss_start = .;
  .bss            :
  {
   s-*(.bss .bss.*)
   a-*(.bss .bss.*)
   g-*(.bss .bss.*)
   *(COMMON)
   . = ALIGN(8);
  } >INTRAM AT>FLASH
  . = ALIGN(8);
  _end = .;

  /* Heap */

  __heap_start__ = ALIGN(8);
  . = ORIGIN(INTRAM) + LENGTH(INTRAM) - 0x1000;
  __heap_end__ = .;

  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }

  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }

  /* Stack */

  .stack         ORIGIN(INTRAM) + LENGTH(INTRAM) - 0x1000 :
  {
    _stack = .;
    *(.stack)
    . = 0x1000;
    _estack = .;
  } >INTRAM AT>FLASH

  /* Other */

  .userpage    :  { *(.userpage .userpage.*) } >USERPAGE AT>USERPAGE
  .factorypage :  { *(.factorypage .factorypage.*) } >FACTORYPAGE AT>FACTORYPAGE
  /DISCARD/    :  { *(.note.GNU-stack) }
}
