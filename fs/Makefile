# Create firmware

FORTH = gforth

VPATH = ../j1_forth

SRC = crossj1.fs \
      basewords.fs \
      nuc.fs \
      main.fs

.PHONY: sim syn

j1.mif j1.hex j1.lst: $(SRC) *.fs
	$(FORTH) main.fs

sim: j1.hex
	cp $^ ..

syn: j1.mif
	cp $^ ../syn
