#CROSS_COMPILE = arm-none-eabi-
CROSS_COMPILE = arm-none-linux-gnueabi-
AS	= $(CROSS_COMPILE)as
LD	= $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJCFLAGS += --gap-fill=0xff
RM	= rm -f

ALL = start.bin

all: $(ALL)

start.bin:	start.elf
	$(OBJCOPY) ${OBJCFLAGS} -O binary $< $@

start.elf:	start.o
	$(LD) -T linkscript.ld -o $@ $< 

start.o:	start.S test.fs
	$(AS) -o start.o start.S


clean:
	$(RM) *.ift *.bin *.o *.elf 
	$(RM) *.*~ 
	$(RM) *~ 