#CROSS_COMPILE = arm-none-eabi-
CROSS_COMPILE = arm-none-linux-gnueabi-
AS	= $(CROSS_COMPILE)as
LD	= $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJCFLAGS += --gap-fill=0xff
RM	= rm -f

ALL = zt-load.bin

all: $(ALL)

zt-load.bin:	zt-load.elf
	$(OBJCOPY) ${OBJCFLAGS} -O binary $< $@

zt-load.elf:	start.o
	$(LD) -T test.ld -o $@ $< 

start.o:	start.S test.fs
	$(AS) -o start.o start.S


clean:
	$(RM) *.ift *.bin *.o *.elf 
	$(RM) *.*~ 
	$(RM) *~ 