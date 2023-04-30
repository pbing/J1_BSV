module[ application"

\ MEM access
\ 32 cycles
URAM
variable a
variable b
variable c
variable d

ROM
: main ( -- 0x9e24 )
    h# 0123 a !
    h# 4567 b !
    h# 89ab c !
    h# cdef d !
    a @
    b @
    c @
    d @
    + + +
    begin again ;

]module
