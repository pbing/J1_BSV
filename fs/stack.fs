module[ application"

\ check stack depth by summing up 1..33
\ expected result: 33 * (33 + 1) / 2 = 561 = 0x0231
\ ~80 cycles
: main ( --- )
    d# 1  d# 2  d# 3  d# 4  d# 5  d# 6  d# 7  d# 8  d# 9  d# 10
    d# 11 d# 12 d# 13 d# 14 d# 15 d# 16 d# 17 d# 18 d# 19 d# 20
    d# 21 d# 22 d# 23 d# 24 d# 25 d# 26 d# 27 d# 28 d# 29 d# 30
    d# 31 d# 32 d# 33
    + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + 
    drop
    begin again ;

]module