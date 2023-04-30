/* J1 Forth CPU */

package J1;

export J1Client_IFC, J1Server_IFC, IORequest, IOResponse, mkJ1;

import BRAMCore::*;
import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Memory::*;
import RegFile::*;
import Reserved::*;

import J1Types::*;

(* synthesize *)
module mkJ1(J1Client_IFC);
   Reg#(Bit#(15))     pc     <- mkReg(0); // program counter
   Reg#(Word)         st0    <- mkRegU;   // top of stack (TOS)
   Reg#(StackPtr)     dsp    <- mkReg(0); // data stack pointer
   Reg#(StackPtr)     rsp    <- mkReg(0); // return stack pointer
   FIFOF#(IORequest)  io_req <- mkGFIFOF(True, False);
   FIFOF#(IOResponse) io_rsp <- mkGFIFOF(False, True);
   Reg#(Bool)         ioWait <- mkReg(False);

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

   function Word alu(Op op);
      /* signed stack operands */
      Int#(16) sst0 = unpack(st0);
      Int#(16) sst1 = unpack(st1);

      case (op)
         OP_T          : alu  = st0;
         OP_N          : alu  = st1;
         OP_T_PLUS_N   : alu  = st0 + st1;
         OP_T_AND_N    : alu  = st0 & st1;
         OP_T_IOR_N    : alu  = st0 | st1;
         OP_T_XOR_N    : alu  = st0 ^ st1;
         OP_INV_T      : alu  = ~st0;
         OP_N_EQ_T     : alu  = (st1 == st0) ? '1 : '0;
         OP_N_LS_T     : alu  = (sst1 < sst0) ? '1 : '0;
         OP_N_RSHIFT_T : alu  = (st0 > 15) ? 0 : st1 >> st0[3:0];
         OP_T_MINUS_1  : alu  = st0 - 1;
         OP_R          : alu  = rst0;
         OP_AT         : alu  = (st0[15:14] == 2'b00) ? ram.b.read : io_rsp.first.data;
         OP_N_LSHIFT_T : alu  = (st0 > 15) ? 0 : st1 << st0[3:0];
         OP_DEPTH      : alu  = {3'b0, rsp, 3'b0, dsp};
         OP_N_ULS_T    : alu  = (st1 < st0) ? '1 : '0;
         default         alu  = ?;
      endcase
   endfunction

   rule rl_run;
      /* instruction fetch */
      Word noop  = 16'h6000;
      let insn   = (pc == 0) ? noop : ram.a.read; // first instruction must always be a NOOP
      let opcode = decode(insn);

      /* execute */
      let _st0 = st0;
      let _dsp = dsp;
      let _rsp = rsp;
      let  _pc = pc;
      let ramWen = False;

      case (opcode) matches
         tagged Lit .value:
            begin
               _dsp = dsp + 1;
               dstack.upd(_dsp, st0);
               _st0 = zeroExtend(value);
               _pc  = pc + 2;
               dsp <= _dsp;
               rsp <= _rsp;
               st0 <= _st0;
               pc  <= _pc;
            end

         tagged Ubranch .target:
            begin
               _pc = zeroExtend(target << 1);
               dsp <= _dsp;
               rsp <= _rsp;
               st0 <= _st0;
               pc  <= _pc;
            end

         tagged Zbranch .target:
            begin
               _dsp = dsp - 1; // predicated jump is like DROP
               _st0 = st1;
               if (st0 == 0)
                  _pc = zeroExtend(target << 1);
               else
                  _pc = pc + 2;
               dsp <= _dsp;
               rsp <= _rsp;
               st0 <= _st0;
               pc  <= _pc;
            end

         tagged Call .target:
            begin
               _rsp = rsp + 1;
               rstack.upd(_rsp, zeroExtend(pc + 2));
               _pc = zeroExtend(target << 1);
               dsp <= _dsp;
               rsp <= _rsp;
               st0 <= _st0;
               pc  <= _pc;
            end

         tagged Alu {r_to_pc:  .r_to_pc,
                     op:       .op,
                     t_to_n:   .t_to_n,
                     t_to_r:   .t_to_r,
                     n_to_mem: .n_to_mem,
                     rstack:   .rstk,
                     dstack:   .dstk}:
            begin
               _st0 = alu(op);

               _dsp = dsp + signExtend(dstk);
               if (t_to_n) dstack.upd(_dsp, st0);

               _rsp = rsp + signExtend(rstk);
               if (t_to_r) rstack.upd(_rsp, st0);

               if (r_to_pc)
                  _pc = truncate(rst0);
               else
                  _pc = pc + 2;

               ramWen = n_to_mem;

               let req = MemoryRequest {write: n_to_mem, byteen: '1, address: st0, data: st1};

               if (st0[15:14] != 2'b00 && n_to_mem)
                  if (io_req.notFull) begin
                     io_req.enq(req); // IO write address
                     dsp <= _dsp;
                     rsp <= _rsp;
                     st0 <= _st0;
                     pc  <= _pc;
                  end
                  else
                     _pc = pc;
               else if (st0[15:14] != 2'b00 && op == OP_AT && !ioWait) begin
                  if (io_req.notFull) begin
                     io_req.enq(req); // IO read adress
                     ioWait <= True;
                  end
                  _pc = pc;
               end
               else if (ioWait && !io_rsp.notEmpty)
                  _pc = pc; // IO read wait
               else if (ioWait && io_rsp.notEmpty) begin
                  io_rsp.deq(); // IO read data
                  ioWait <= False;
                  dsp <= _dsp;
                  rsp <= _rsp;
                  st0 <= _st0;
                  pc  <= _pc;
               end
               else begin
                  // non-IO default case
                  dsp <= _dsp;
                  rsp <= _rsp;
                  st0 <= _st0;
                  pc  <= _pc;
               end
            end
      endcase

      ram.a.put(False, _pc[14:1], 0);

      /* Address RAM with _st0 to ensure read in current cycle */
      ram.b.put(_st0[15:14] == 2'b00 && ramWen, _st0[14:1], st1);

      $display("%t: pc=%h insn=%h dsp=%h st0=%h st1=%h rsp=%h rst0=%h", $time, pc, insn, dsp, st0, st1, rsp, rst0);
      //$display("%t: ", $time, fshow(opcode));
   endrule

   return toGPClient(io_req, io_rsp);
endmodule

endpackage
