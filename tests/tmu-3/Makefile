default: ada_crt0.o test.gpr
	gnatmake -P test

ada_crt0.o: ada_crt0.S avr32.h
	avr32-gcc -c ada_crt0.S

clean:
	rm -rf ada_crt0.o
	gnatclean main

install:
	avr32program -cUSB program -F elf -finternal@0x80000000,512Kb -e -v -R -r main