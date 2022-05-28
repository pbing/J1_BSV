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

   rule rl_serve_io;
      let req = io_req.first;
      io_req.deq();
      $display("%t: IO_REQ = ", $time, fshow(req));

      if (!req.write) begin
         let rsp   = MemoryResponse {data: ~req.address};
         io_rsp.enq(rsp);
         $display("%t: IO_RSP = ", $time, fshow(rsp));
      end
   endrule

   return toGPServer(io_req, io_rsp);
endmodule


endpackage
