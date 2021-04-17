#!/bin/zsh
BDIR=bdir
VDIR=rtl
SIMDIR=simdir

mkdir -p $BDIR $VDIR $SIMDIR

export RTL_OPTIONS="-opt-undetermined-vals -unspecified-to X"

export BSC_OPTIONS="-p src:test:+ -bdir $BDIR -vdir $VDIR -simdir $SIMDIR -o bsim"

# uncomment for better RTL synthesis results
#export BSC_OPTIONS="$BSC_OPTIONS $RTL_OPTIONS"

