module[ application"

\ IO access
\ 48 cycles
: main ( -- 0x9e24 )
    h# 0123 h# 4000 !
    h# 4567 h# 4002 !
    h# 89ab h# 4004 !
    h# cdef h# 4006 !
    h# 4000 @
    h# 4002 @
    h# 4004 @
    h# 4006 @
    + + +
    begin again ;

]module
