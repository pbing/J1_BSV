# Description
[J1: a small Forth CPU Core for FPGAs](http://excamera.com/sphinx/fpga-j1.html)

Rewritten in Bluespec SystemVerilog (BSV) from [Verilog Source](https://github.com/ros-drivers/wge100_driver/tree/hydro-devel/wge100_camera_firmware/src/hardware/verilog/j1.v).

## Create an environment for BSC
```shell
source env.sh
```

## Simulate
```shell
bsc -sim -u ./test/Tb.bsv
bsc -sim -e mkTb
./bsim
```

## Create RTL
```shell
bsc -verilog -u ./src/J1.bsv
```
