/* J1 Forth CPU */

package J1;

export J1Client_IFC, J1Server_IFC, mkJ1;

import BRAMCore::*;
import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Memory::*;
import RegFile::*;
import Reserved::*;

import J1Types::*;
import J1Alu::*;

(* synthesize *)
module mkJ1(J1Client_IFC);
   Reg#(Bit#(15))                pc     <- mkReg(0); // process counter
   Reg#(Word)                    st0    <- mkRegU;   // top of stack (TOS)
   Reg#(StackPtr)                dsp    <- mkReg(0); // data stack pointer
   Reg#(StackPtr)                rsp    <- mkReg(0); // return stack pointer
   FIFO#(MemoryRequest#(16, 16)) io_req <- mkFIFO;
   FIFOF#(MemoryResponse#(16))   io_rsp <- mkUGFIFOF;

   /* Dual-Port RAM 16Kx16
   *  port a: instruction
   *  port b: data
   */
   BRAM_DUAL_PORT#(RamAddr, Word) ram <- mkBRAMCore2Load(2**14, False, "j1.hex", False);

   /* data stack 32x16 + st0 */
   RegFile#(StackPtr, Word) dstack <- mkRegFileFull;
   let st1 = dstack.sub(dsp); // next of stack (NOS)

   /* return stack 32x16 */
   RegFile#(StackPtr, Word) rstack <- mkRegFileFull;
   let rst0 = rstack.sub(rsp); // top of return stack (TOR)
   
   function DecodedInst decode(Word x);
      return case (x[15:13])
                3'b000: tagged Ubranch x[12:0];
                3'b001: tagged Zbranch x[12:0];
                3'b010: tagged Call x[12:0];
                3'b011: tagged Alu unpack(x[12:0]);
                default tagged Lit x[14:0];
             endcase;
   endfunction

   rule run;
      /* instruction fetch */
      Word noop  = 16'h6000;
      let insn   = (pc == 0) ? noop : ram.a.read; // first instruction must always be a NOOP
      let opcode = decode(insn);

      /* execute */
      let _st0 = st0;
      let _dsp = dsp;
      let _rsp = rsp;
      let  _pc = pc;
      Bool wen = False;
      Bool ren = False;

      case (opcode) matches
         tagged Lit .value:
            begin
               _dsp = dsp + 1;
               dstack.upd(_dsp, st0);
               _st0 = zeroExtend(value);
               _pc  = pc + 2;
            end

         tagged Ubranch .target:
            begin
               _pc = zeroExtend(target << 1);
            end

         tagged Zbranch .target:
            begin
               _dsp = dsp - 1; // predicated jump is like DROP
               _st0 = st1;
               if (st0 == 0)
                  _pc = zeroExtend(target << 1);
               else
                  _pc = pc + 2;
            end

         tagged Call .target:
            begin
               _rsp = rsp + 1;
               rstack.upd(_rsp, zeroExtend(pc + 2));
               _pc = zeroExtend(target << 1);
            end

         tagged Alu {r_to_pc:  .r_to_pc,
                     op:       .op,
                     t_to_n:   .t_to_n,
                     t_to_r:   .t_to_r,
                     n_to_mem: .n_to_mem,
                     rstack:   .rstk,
                     dstack:   .dstk}:
            begin
               wen = n_to_mem;
               ren = (op == OP_AT) && !wen;

               Word rdata;
               if (st0[15:14] == 0)
                  rdata = ram.b.read;
               else if (io_rsp.notEmpty) begin
                  rdata = io_rsp.first.data;
                  io_rsp.deq();
               end
               else
                  rdata = st0;
               
               _st0 = alu(op, st0, st1, rst0, rdata, dsp, rsp);

               _dsp = dsp + signExtend(dstk);
               if (t_to_n)
                  dstack.upd(_dsp, st0);

               _rsp = rsp + signExtend(rstk);
               if (t_to_r)
                  rstack.upd(_rsp, st0);
               
               if (r_to_pc)
                  _pc = truncate(rst0);
               else
                  _pc = pc + 2;
            end
      endcase

      ram.a.put(False, _pc[14:1], 0);

      if (_st0[15:14] == 0)
         ram.b.put(wen, _st0[14:1], st1);
      else if (ren || wen) begin
         let req = MemoryRequest {write: wen, byteen: '1, address: _st0, data: st1};
         io_req.enq(req);
      end

      dsp <= _dsp;
      rsp <= _rsp;
      st0 <= _st0;
      pc  <= _pc;

      $display("%t: pc=%h insn=%h dsp=%h st0=%h st1=%h rsp=%h rst0=%h",
         $time, pc, insn, dsp, st0, st1, rsp, rst0);
      //$display("%t: ", $time, fshow(opcode));
   endrule

   /* Use interface methods instead of
   * <return toGPClient(io_req, io_rsp);>
   * because io_rsp in an unguarded FIFO
   */
   interface request = toGet(io_req);

      interface Put response;
         method Action put(rsp) if (io_rsp.notFull);
            io_rsp.enq(rsp);
         endmethod
      endinterface
endmodule

endpackage
