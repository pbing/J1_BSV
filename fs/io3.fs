module[ application"

\ IO access
\ 12 cycles
: main ( --- 55 )
    h# 1234 h# 4000 !
    h# 4000 @
    begin again ;

]module
