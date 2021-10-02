/* Dummy I/O module */

package DummyIO;

import ClientServer::*;
import FIFO::*;
import GetPut::*;
import Memory::*;

import J1::*;

(* synthesize *)
module mkDummyIO(J1Server_IFC);
   FIFO#(MemoryRequest#(16, 16)) io_req <- mkFIFO;
   FIFO#(MemoryResponse#(16))    io_rsp <- mkFIFO;

   //rule serve_io;
   //   let req <- dut.request.get;
   //   $display("%t IO_REQ=", $time, fshow(req));
   //
   //   MemoryResponse#(16) rsp = MemoryResponse {data: ?};
   //   dut.response.put(rsp);
   //   $display("%t IO_RSP=", $time, fshow(rsp));
   //endrule

  // interface Get response = toGet(io_rsp);
   interface Get response;
      method ActionValue#(MemoryResponse#(16)) get();
         return MemoryResponse {data: ?};
      endmethod
   endinterface

   //interface Put request  = toPut(io_req);
   interface Put request;
      method Action put(x);
      endmethod
   endinterface
endmodule


endpackage
