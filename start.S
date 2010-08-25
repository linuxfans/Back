@filename: start.S
	.text
	.align 4
	.global _start
	
	top	.req	r11
	rsp	.req	sp
	psp	.req	r12
	
_start:	
	b	reset
	
	.text
FORTH_FILE:
	.incbin "test.fs"	
	.word	0x0
	.align 4
	.text
	.set link,0
	
	.macro defcode name, namelen, flags=0, label
	.section .rodata	
	.align 4
	.globl name_\label
name_\label :
	.int link
	.set link,name_\label
	.byte \flags+\namelen
	.ascii "\name"	
	.align 4	
	.globl code_\label
code_\label :
	.endm

	.macro defword name, namelen, flags=0, label
	.section .rodata	
	.align 4
	.globl name_\label
name_\label :
	.int link
	.set link,name_\label
	.byte \flags+\namelen
	.ascii "\name"	
	.align 4	
	.globl code_\label
code_\label :
	DOCOL
	.endm
	
	.macro defvar name, namelen, flags=0, label, initial=0
	defcode \name,\namelen,\flags,\label
	PUSH	top
	ldr	top, =var_\name
	NEXT
	.data
	.align 4
var_\name :
	.word \initial
	.endm
	
	.macro NEXT
	mov	pc, lr
	.endm
	
	.macro	DOCOL
	PUSHRSP	lr
	.endm	

	.macro PUSHRSP reg
	stmfd	rsp!, {\reg}
	.endm

	.macro POPRSP reg
	ldmfd	rsp!, {\reg}
	.endm
	
	.macro PUSH reg
	stmfd	psp!, {\reg}
	.endm
	
	.macro POP reg
	ldmfd	psp!, {\reg}
	.endm
	
reset:	
	@@ set the cpu to SVC32 mode 
	mrs	r0,cpsr
	bic	r0,r0,#0x1f
	orr	r0,r0,#0xd3
	msr	cpsr,r0

	@@ 
	ldr	r0, =dictionary
	ldr	r1, =var_HERE
	str	r0, [r1]
	
	ldr	r0, =FORTH_FILE
	ldr	r1, =var_TIB
	str	r0, [r1]
	ldr	sp, =return_stack_top
	ldr	r12,=parameter_stack_top
	
MAIN_LOOP:
	bl	code_INTERPRET
	b	MAIN_LOOP

	defword "INTERPRET",9,,INTERPRET
	bl	_WORD
	bl	_FIND
	cmp	top, #0		@ top = link address
	beq	2f		@ Not Found
	ldrb	r0, [top, #4]
	and	r1, r0, #F_IMMED
	ldr	r3, =var_STATE
	ldr	r3, [r3]
	add	r1, r1, r3
	cmp	r1, #0	
	bne	1f		@ Immediate word, jmp to 1f
	and	r0, r0, #F_LENMASK
	add	r0, r0, top	@ r0+4(link filed)+4(flag_len+3)-8(bl offset)
	and	r0, r0, #~3     @ r0: CFA of the word is being compiled
	ldr	r1, =var_HERE
	ldr	r1, [r1]	@ r1: HERE
	sub	r2, r0, r1	@ r2: offset
	mov	r2, r2, LSR #2
	and	r2, r2, #0x00FFFFFF
	add	top, r2, #0xEB000000
	bl	code_COMMA
	bl	code_EXIT	
1:
	and	r0, r0, #F_LENMASK
	add	r0, r0, #1	
	add	r0, r0, top
	add	r0, r0, #3
	and	r0, r0, #~3
	POP	top
	mov	lr, pc
	mov	pc, r0
	bl	code_EXIT
2:
	@@ Is it a number?
	mov	r2, #0
	POP	r0
	ldrb	r1, [r0], #1
	cmp	r1, $'0'
	bhi	nothex		@ Higher than '0', not hex
	ldrb	r1, [r0], #1
	cmp	r1, $'x'
	bne	error		@ Not start with "0x", error
	mov	r2, #0	
3:
	ldrb	r1, [r0], #1
	cmp	r1, $' '
	bls	over
	mov	r2, r2, lsl #4
	cmp	r1, $'0'
	blt	error		@ Less than '0', error
	cmp	r1, $'9'
	bhi	4f
	sub	r1, r1, $'0'
	add	r2, r2, r1
	b	3b
4:
	cmp	r1, $'A'
	blt	error
	cmp	r1, $'F'
	bhi	5f
	sub	r1, r1, $'7'	@ 'A'-10 = 65-10 = 55 = '7'
	add	r2, r2, r1
	b	3b
5:	
	cmp	r1, $'a'
	blt	error
	cmp	r1, $'f'
	bhi	error
	sub	r1, r1, $'W'	@ 'a'-10 = 97-10 = 87 = 'W'
	add	r2, r2, r1
	b	3b

over:
	mov	top, r2
	ldr	r3, =var_STATE
	ldr	r3, [r3]
	cmp	r3, #0
	bne	6f		@ Immediat mode
	ldr	r3, =code_LIT
	sub	r3, r3, #8
	ldr	r1, =var_HERE
	ldr	r1, [r1]	@ r1: HERE
	sub	r2, r3, r1	@ r2: offset
	mov	r2, r2, LSR #2
	and	r2, r2, #0x00FFFFFF
	PUSH	top
	add	top, r2, #0xEB000000
	bl	code_COMMA
	ldr	r1, =var_HERE	
	ldr	r1, [r1]	@ r1: HERE
	bl	code_COMMA
6:
	bl	code_EXIT	
nothex:
error:	
	b	END_LOOP

	defvar "STATE",5,,STATE
	defvar "HERE",4,,HERE
	defvar "LATEST",6,,LATEST, name_OVER
	defvar "S0",2,,SZ
	defvar "TIB",3,,TIB

	@@ Create New Word
	defcode "CREATE",6,,CREATE
_CREATE:
	ldr	r0, =var_HERE
	ldr	r0, [r0]	@ r0 = HERE
	ldr	r1, =var_LATEST	@ r1 = &LATEST
	ldr	r2, [r1]	@ r2 = LATEST
	str	r0, [r1]	@ Update LATEST	
	str	r2, [r0]	@ Save link
	
	add	r1, r0, #4	@ Move HERE
	ldr	r0, =var_HERE
	
	strb	top, [r1]	@ Store length & flags
	add	r1, r1, #1
	add	top, r1, top	@
	POP	r3		@ address of name
1:
	ldrb	r2, [r3], #1
	strb	r2, [r1], #1
	cmp	top, r1
	bne	1b
	add	r1, r1, #3	@ Align HERE to 4byte boundary
	and	r1, r1, #~3
	str	r1, [r0]	@ Update HERE
	POP	top
	NEXT

	@@ Enter interpret mode
	defcode "[",1,F_IMMED,LBRAC
	ldr	r0, =var_STATE
	mov	r1, #1
	str	r1, [r0]
	NEXT
	
	@@ Enter compile mode
	defcode "]",1,,RBRAC
	ldr	r0, =var_STATE
	mov	r1, #0
	str	r1, [r0]	
	NEXT

	@@ Lit
	defcode "LIT",3,,LIT
	PUSH	top
	ldr	top, [lr]
	add	lr, lr, #4
	NEXT
	
	@@ 
	defcode "EXIT",4,,EXIT
	POPRSP 	lr
	NEXT
	
	@@ 
	defcode ",",1,,COMMA
	ldr	r0, =var_HERE
	ldr	r1, [r0]
	str	top, [r1]
	add	r1, r1, #4
	POP	top
	str	r1, [r0]
	NEXT
	
	@@ 
	defcode "!",1,,STORE
	POP	r0
	str	r0, [top]
	POP	top
	NEXT

	@@ 
	defcode "@",1,,FETCH
	ldr	top, [top]
	NEXT

	@@ 
	defcode "+",1,,PLUS
	POP	r0
	add	top, top , r0
	NEXT

	@@ 
	defcode "AND",3,,AND
	POP	r0
	and	top, top , r0
	NEXT
	
	
	@@
	defword ";",1,F_IMMED,SEMICOLON
	bl	code_LIT
	POPRSP 	lr	
	bl	code_COMMA
	bl	code_LIT
	NEXT
	bl	code_COMMA
	bl	code_LBRAC
	bl	code_EXIT

	@@ 
	defword ":",1,F_IMMED,COLON
	bl	_WORD
	bl	_CREATE
	bl	code_LIT
	DOCOL
	bl	code_COMMA
	bl	code_RBRAC
	bl	code_EXIT
	
	@@ ( -- addr length )
	defword "WORD", 4, , WORD
	bl	_WORD
	bl	code_EXIT	
_WORD:
	ldr	r0, =var_TIB
	ldr	r0, [r0]
1:
	ldrb	r1, [r0], #1
	cmp	r1, #0
	beq	END_LOOP
	cmp	r1, $'\\'
	beq	3f
	cmp	r1, $' '
	bls	1b
	sub	r2, r0, #1
	PUSH	top
	PUSH	r2
	mov	top, #0		@ top = word's length
2:
	add	top, top, #1
	ldrb	r1, [r0], #1
	cmp	r1, #0
	beq	END_LOOP	
	cmp	r1, $' '	
	bhi	2b
	add	r1, top, #0x30
	ldr	r1, =var_TIB
	str	r0, [r1]
	NEXT
3:
	ldrb	r1, [r0], #1
	cmp	r1, $'\n'
	bne	3b
	b	1b
	
	.set F_IMMED,0x80
	.set F_HIDDEN,0x20
	.set F_LENMASK,0x1f

	defword "FIND", 4, , FIND
	bl	_FIND
	bl	code_EXIT
_FIND:
	add	r0, top, #0x30
	ldr	r0, =var_LATEST
1:
	ldr	r0, [r0]
	cmp	r0, #0
	beq	3f
	ldrb	r1, [r0, #4]
	and	r1, r1, #F_LENMASK
	add	r5, r1, #0x30
	cmp	r1, top
	bne	1b
2:
	sub	r1, r1, #1
	add	r3, r1, #5
	ldrb	r2, [r0, r3]
	ldr	r3, [psp]
	ldrb	r3, [r3, r1]
	cmp	r2, r3
	bne	1b		@ Different character, move to next word in dict
	cmp	r1, #0
	bne	2b		@ Continue to compare
	ldrb	r1, [r0, #4]
	and	r1, r1, #F_LENMASK
	add	r1, #0x30
	POP	top
	mov	top, r0
	NEXT
3:
	mov	top, #0
	NEXT

	defcode "DROP",4,,DROP
	POP	top
	NEXT

	defcode "SWAP",4,,SWAP
	POP	r0
	PUSH	top
	mov	top, r0
	NEXT

	defcode "DUP",3,,DUP
	PUSH	top
	NEXT

	defcode "OVER",4,,OVER
	ldr	r0, [psp]
	PUSH	top
	mov	top, r0
	
	
END_LOOP:
TRUE_END_LOOP:	
	b	TRUE_END_LOOP

	.data			
	.set RETURN_STACK_SIZE,512
	.set PARAMETER_STACK_SIZE,512
	.set DICTIONARY_SIZE,4096
	.data
	.align 4
	.space 512
return_stack:
	.space RETURN_STACK_SIZE
return_stack_top:
	.align 4
parameter_stack:
	.space PARAMETER_STACK_SIZE
parameter_stack_top:
dictionary:
	.space	DICTIONARY_SIZE
