module[ application"

\ IO access
\ 7 cycles
: main ( --- 55 )
    h# 1234 h# 4000 !
    begin again ;

]module
