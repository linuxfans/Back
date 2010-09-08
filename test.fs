: init-uart
    0x00 0x101F1030 !
    0x39 0x101F1024 !
    0x04 0x101F1028 !
    0x70 0x101F102C !
    0x301 0x101F1030 !
;
: '\n'
    0x0A
;
: EMIT
    0x101F1000 !
;
: CR
    '\n'
    EMIT
;

: hello-world
    0x48 EMIT
    0x65 EMIT
    0x6c EMIT
    0x6c EMIT
    0x6F EMIT
    0x20 EMIT
    0x57 EMIT
    0x6F EMIT
    0x72 EMIT
    0x6C EMIT
    0x64 EMIT
    0x21 EMIT
    0x0a EMIT
    0x0d EMIT                    
;

: >CFA
    DUP 0x4 + C@
    0x1F AND    
    +
    0xFFFFFFFC AND
;

: BRANCH
    HERE @ 
    -
    0x02 LSR
    0x00FFFFFF AND
    0xEB000000 +
    ,
;

: COMPILE
    WORD FIND
    >CFA
    BRANCH
;

: ' IMMEDIATE
    WORD FIND
    >CFA
;

: [COMPILE] IMMEDIATE
    COMPILE
;

: 0BRANCH IMMEDIATE
    LIT ' 0= [ , ]
    BRANCH
    
    LIT
    ' DROP [ , ]
    BRANCH
    
    HERE @ 
    DUP 0x0B000000 SWAP !		\ Save bleq to HERE
    DUP 0x04 +
    HERE !
;


: IF IMMEDIATE
    [COMPILE] 0BRANCH
;

: ELSE IMMEDIATE
    DUP DUP
    0x04 +				\ pc - 4 = top + 4 
    HERE @				\ get current HERE, tar = HERE + 4
    SWAP -				\ off = tar - pc 
    0x02 LSR
    0x00FFFFFF AND
    SWAP @				\ Get bleq or bl
    +					\ bleq or bl off
    SWAP !
    
    HERE @ 
    DUP 0xEB000000 SWAP !		\ Save bl to HERE
    DUP 0x04 +
    HERE !
;

: THEN IMMEDIATE
    DUP DUP
    0x08 +				\ pc = top + 8
    HERE @				\ get current HERE
    SWAP -				\ off = tar - pc
    0x02 LSR
    0x00FFFFFF AND
    SWAP @				\ Get bleq or bl
    +					\ bleq or bl off
    SWAP !
;

: BEGIN IMMEDIATE
    HERE @
;

: UNTIL IMMEDIATE
    LIT
    ' 0= [ , ]
    BRANCH
    
    LIT
    ' DROP [ , ]
    BRANCH

    HERE @			     \ get current HERE, HERE = pc - 8
    0x08 +				
    -				      \ off = tar - pc = sop - top + 8
    0x02 LSR
    0x00FFFFFF AND
    0x0B000000
    +					\ bleq or bl off
    ,
;

: VARIABLE
    WORD CREATE
;

: 测试 
    0x09 S0 !
    BEGIN
	S0 @
	DUP
	0x30 +
	EMIT
	0x01 -
	DUP
	S0 !
	0= 
    UNTIL
    CR
    0x00 IF 0x31 EMIT CR ELSE 0x30 EMIT CR THEN
    0x10 IF 0x31 EMIT CR ELSE 0x30 EMIT CR THEN
    
;

: 测试2
    测试
;

init-uart 测试2
