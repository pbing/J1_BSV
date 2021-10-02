/* Testbench */

package Tb;

import Connectable::*;

import DummyIO::*;
import J1::*;

(* synthesize *)
module mkTb(Empty);
   J1Client_IFC dut <- mkJ1;
   J1Server_IFC io  <- mkDummyIO;

   mkConnection(dut, io);
endmodule

endpackage
