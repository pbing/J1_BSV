module[ application"

\ 10th fibonacci
\ with no memory access
\ 179 cycles
: main ( --- 55 )
    d# 1 d# 1
    d# 8 0do  tuck +  loop
    nip
    begin again ;

]module
