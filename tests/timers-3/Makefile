default:
	avr32-gnatmake -P test

clean:
	avr32-gnatclean -P test

install:
	avr32program -cUSB program -F elf -finternal@0x80000000,512Kb -e -v -R -r main

debug:
	avr32gdbproxy -finternal@0x80000000,512Kb -a localhost:4242
