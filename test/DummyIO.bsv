/* Dummy I/O module */

package DummyIO;

import ClientServer::*;
import FIFO::*;
import GetPut::*;
import Memory::*;
import RegFile::*;

import J1::*;

(* synthesize *)
module mkDummyIO(J1Server_IFC);
   FIFO#(IORequest)            io_req <- mkFIFO;
   FIFO#(IOResponse)           io_rsp <- mkFIFO;
   RegFile#(Bit#(2), Bit#(16)) rf_io <- mkRegFileFull; // 4 dummy registers

   rule rl_serve_io;
      let req = io_req.first;
      io_req.deq();
      $display("%t: IO_REQ = ", $time, fshow(req));

      Bit#(2) rf_addr = truncate(req.address >> 1);

      if (req.write)
         rf_io.upd(rf_addr, req.data);
      else begin
         let rsp = MemoryResponse {data: rf_io.sub(rf_addr)};
         io_rsp.enq(rsp);
         $display("%t: IO_RSP = ", $time, fshow(rsp));
      end
   endrule

   return toGPServer(io_req, io_rsp);
endmodule

endpackage
