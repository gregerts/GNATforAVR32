# Run-time settings
INSTALL_DIR = ../build
RTS_NAME    = ravenscar

# Machine settings
MARCH = ucr1
MPART = uc3a0512

# Source files for Ravenscar LIBGNAT
LIBGNAT_ADA_SRC = \
system.ads   \
ada.ads      \
a-except.ads \
gnat.ads     \
g-souinf.ads \
g-io.ads     \
interfac.ads \
i-c.ads      \
s-assert.ads \
s-stoele.ads \
s-maccod.ads \
s-unstyp.ads \
s-fatflt.ads \
s-fatlfl.ads \
s-fatllf.ads \
s-fatsfl.ads \
s-memory.ads \
s-secsta.ads \
a-tags.ads   \
s-sssita.ads \
s-bb.ads     \
s-bbcppr.ads \
s-bbinte.ads \
s-bbpara.ads \
s-bbpere.ads \
s-bbperi.ads \
s-bbprot.ads \
s-bbseou.ads \
s-bbthqu.ads \
s-bbthre.ads \
s-bbtime.ads

LIBGNAT_ASM_SRC = \
context_switch.S \
exception_handler.S \
trampoline.S

LIBGNAT_OBJS = $(LIBGNAT_ADA_SRC:.ads=.o) $(LIBGNAT_ASM_SRC:.S=.o)
LIBGNAT_ALIS = $(LIBGNAT_ADA_SRC:.ads=.ali)

# Source files for Ravenscar LIBGNARL
LIBGNARL_SRC  = \
s-parame.ads \
s-purexc.ads \
s-osinte.ads \
s-tasinf.ads \
s-taspri.ads \
s-taprop.ads \
s-taskin.ads \
s-interr.ads \
a-interr.ads \
a-intnam.ads \
a-reatim.ads \
a-retide.ads \
a-rttiev.ads \
s-taprob.ads \
s-tasdeb.ads \
s-tasres.ads \
s-tarest.ads \
s-tposen.ads \
a-sytaco.ads \
a-taside.ads \
a-taster.ads \
a-exetim.ads \
a-extiin.ads \
a-extiti.ads \
a-etinti.ads

LIBGNARL_OBJS = $(LIBGNARL_SRC:.ads=.o)
LIBGNARL_ALIS = $(LIBGNARL_SRC:.ads=.ali)

ADA_SRC = $(LIBGNAT_ADA_SRC) $(LIBGNARL_SRC)

# Compiler flags
ADA_FLAGS = -O2 -gnatanpg -g -march=$(MARCH) -mpart=$(MPART)
ASM_FLAGS = -march=$(MARCH) -mpart=$(MPART)

# Utils
CC	    = /usr/local/bin/avr32-gcc
BIN	    = avr32-objcopy
SIZE	    = avr32-size
AS          = avr32-as
AR	    = avr32-ar
RANLIB      = avr32-ranlib
MV	    = mv
CP          = cp
RM	    = rm -f
RMDIR       = rm -rf
MKDIR       = mkdir
CHMOD       = chmod

# ------------------------------------------	

all: gnat.adc libgnat.a libgnarl.a ada_crt0.o

gnat.adc:
	echo "pragma Profile (Ravenscar);" > gnat.adc

libgnat.a: $(LIBGNAT_OBJS) $(LIBGNAT_ALIS)
	$(AR) cr $@ $(LIBGNAT_OBJS)
	$(RANLIB) $@

libgnarl.a: $(LIBGNARL_OBJS) $(LIBGNARL_ALIS)
	$(AR) cr $@ $(LIBGNARL_OBJS)
	$(RANLIB) $@

ada_crt0.o: ada_crt0.S
	$(CC) -c $(ASM_FLAGS) ada_crt0.S

s-traceb.ali s-traceb.o: s-traceb.adb s-traceb.ads
	$(CC) -c $(ADA_FLAGS) -fno-optimize-sibling-calls s-traceb.adb

s-tasdeb.ali s-tasdeb.o: s-tasdeb.adb s-tasdeb.ads
	$(CC) -c $(ADA_FLAGS) -g -O0 s-tasdeb.adb

a-except.ali a-except.o: a-except.adb a-except.ads
	$(CC) -c $(ADA_FLAGS) -g -fno-inline -O1 a-except.adb

s-assert.ali s-assert.o: s-assert.adb s-assert.ads
	$(CC) -c $(ADA_FLAGS) -g -O2 s-assert.adb

%.ali %.o : %.adb %.ads
	$(CC) -c $(ADA_FLAGS) $< 

%.ali %.o : %.ads
	$(CC) -c $(ADA_FLAGS) $< 

%.o : %.S avr32.h
	$(CC) -c $(ASM_FLAGS) $<

install:
	$(RMDIR) $(INSTALL_DIR)
	$(MKDIR) $(INSTALL_DIR)
	$(MKDIR) $(INSTALL_DIR)/adalib
	$(MKDIR) $(INSTALL_DIR)/adainclude
	$(CP) -r *.ads *.adb $(INSTALL_DIR)/adainclude
	$(CP) -r *.a   $(INSTALL_DIR)/adalib
	$(CP) -r *.ali $(INSTALL_DIR)/adalib
	$(CHMOD) a-wx $(INSTALL_DIR)/adainclude/*.ads
	$(CHMOD) a-wx $(INSTALL_DIR)/adainclude/*.adb
	$(CHMOD) a-wx $(INSTALL_DIR)/adalib/*.a
	$(CHMOD) a-wx $(INSTALL_DIR)/adalib/*.ali
	$(CP) -r ada_crt0.o $(INSTALL_DIR)
	$(CP) -r *.x $(INSTALL_DIR)

clean:
	$(RM) *.o
	$(RM) *.ali
	$(RM) libgnat.a
	$(RM) libgnarl.a
