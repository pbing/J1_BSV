# Create firmware

FORTH = gforth

VPATH = ../j1_forth

.PHONY: sim syn

j1.mif j1.hex j1.lst: $(wildcard *.fs)
	$(FORTH) main.fs

sim: j1.hex
	cp $^ ..

syn: j1.mif
	cp $^ ../syn
