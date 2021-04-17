#!/bin/zsh
SRC=src
BDIR=bdir
VDIR=rtl

mkdir -p $BDIR $VDIR

bsc -p $SRC:+ -bdir $BDIR -vdir $VDIR -verilog -u $@
