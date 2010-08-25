: init-uart
    0x00 0x101F1030 !
    0x39 0x101F1024 !
    0x04 0x101F1028 !
    0x70 0x101F102C !
    0x301 0x101F1030 !
;

: hello-world
    0x48 0x101F1000 !
    0x65 0x101F1000 !
    0x6c 0x101F1000 !
    0x6c 0x101F1000 !
    0x6F 0x101F1000 !
    0x20 0x101F1000 !
    0x57 0x101F1000 !
    0x6F 0x101F1000 !
    0x72 0x101F1000 !
    0x6C 0x101F1000 !
    0x64 0x101F1000 !
    0x21 0x101F1000 !
    0x0a 0x101F1000 !
    0x0d 0x101F1000 !                    
;

: he
    0x48 0x101F1000 !        
    [ hello-world ]
    hello-world     
;
: h2
    he he
;

: '
    WORD FIND
    DUP
    0x04 + @
    0x1F AND
    +	
    0x08 +
    0xFFFFFFFC AND
;

: ABC
    0x33 S0 !
    S0 @
    0x101F1000 !
    TIB @ 0x00 + @
    0x101F1000 !
    TIB @ 0x01 + @
    0x101F1000 !    
    TIB @ 0x02 + @
    0x101F1000 !    
    TIB @ 0x03 + @
    0x101F1000 !    
;
    
init-uart he  ' FIND
