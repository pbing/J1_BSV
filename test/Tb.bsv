package Tb;

import ClientServer::*;
import Types::*;
import J1::*;

module mkTb(Empty);
   IOClient dut <- mkJ1;
   
endmodule

endpackage
