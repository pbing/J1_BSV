\ Compile the firmware

include ../j1_forth/crossj1.fs
include ../j1_forth/basewords.fs

target

\ low high  type          name
$0000 $1fff cdata section ROM  \ ROM
$2000 $27ff udata section URAM \ uninitalized RAM
\ ... ...   idata section IRAM \ initalized RAM

\ I/O addresses
$5000 constant gpio
$6000 constant sw
$7000 constant led

ROM
4 org

module[ everything"

include ../j1_forth/nuc.fs

\ include stack.fs
\ include fib1.fs
\ include fib2.fs
include multdiv.fs
\ include io1.fs
\ include io2.fs

]module

0 org

code 0jump
    $6000 t, \ first instruction must always be a NOOP
    main ubranch
end-code

\ **********************************************************************

meta
hex

: create-output-file w/o create-file throw to outfile-id ;

\ for RTL simulation
s" j1.hex" create-output-file
:noname
    2000 0 do
       i t@ s>d <# # # # # #> type cr
    2 +loop
; execute

\ for Quartus II synthesis
s" j1.mif" create-output-file
:noname
   s" -- Quartus II generated Memory Initialization File (.mif)" type cr
   s" WIDTH=16;" type cr
   s" DEPTH=4096;" type cr
   s" ADDRESS_RADIX=HEX;" type cr
   s" DATA_RADIX=HEX;" type cr
   s" CONTENT BEGIN" type cr

    2000 0 do
       4 spaces
       i 2/ s>d <# # # # # #> type s"  : " type
       i t@ s>d <# # # # # #> type [char] ; emit cr
    2 +loop

   s" END;" type cr
; execute

s" j1.lst" create-output-file
0 1000 disassemble-block

bye
