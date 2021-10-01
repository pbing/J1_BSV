package Tb;

import ClientServer::*;
import GetPut::*;
import Memory::*;

import J1::*;

(* synthesize *)
module mkTb(Empty);
   J1_IFC dut <- mkJ1;
   
   rule serve_io;
      let req <- dut.request.get;
      $display("%t IO_REQ=", $time, fshow(req));
      
      MemoryResponse#(16) rsp = MemoryResponse {data: ?};
      dut.response.put(rsp);
      $display("%t IO_RSP=", $time, fshow(rsp));
   endrule
endmodule

endpackage
