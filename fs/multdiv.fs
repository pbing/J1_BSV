module[ application"

\ check multiplication and division
\ 1938 cycles
: main ( -- 31415 )
    d# 10000 d# 355 d# 113 */ \ 31415 ($7ab7)
    begin again ;

]module
