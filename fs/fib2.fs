module[ application"

\ 10th fibonacci
\ with memory access
\ 301 cycles
URAM
variable a
variable b

ROM
: main ( -- 55 )
    d# 1 a !  d# 1 b !
    d# 8 0do
       a @  b @  tuck +  b !  a !
    loop
    b @
    begin again ;

]module
