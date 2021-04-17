# Description
[J1: a small Forth CPU Core for FPGAs](http://excamera.com/sphinx/fpga-j1.html)

Rewritten in Bluespec SystemVerilog (BSV) from [Verilog Source](https://github.com/ros-drivers/wge100_driver/tree/hydro-devel/wge100_camera_firmware/src/hardware/verilog/j1.v).

Create an environment for BSC
```shell
source env.sh
```

Simulate
```shell
bsc -sim -g mkTb -u ./test/Tb.bsv
bsc -sim -e mkTb
./sim
```

Create RTL
```shell
bsc -verilog -g mkJ1 -u ./src/J1.bsv
```
