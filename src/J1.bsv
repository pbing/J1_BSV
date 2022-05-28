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

typedef Bit#(16) Word;
typedef Bit#(5)  StackPtr;
typedef Bit#(2)  StackOff;
typedef Bit#(14) RamAddr;

typedef enum {
   OP_T,
   OP_N,
   OP_T_PLUS_N,
   OP_T_AND_N,
   OP_T_IOR_N,
   OP_T_XOR_N,
   OP_INV_T,
   OP_N_EQ_T,
   OP_N_LS_T,
   OP_N_RSHIFT_T,
   OP_T_MINUS_1,
   OP_R,
   OP_AT,
   OP_N_LSHIFT_T,
   OP_DEPTH,
   OP_N_ULS_T
   } Op deriving (Bits, Eq, FShow);

typedef union tagged {
   Bit#(15) Lit;
   Bit#(13) Ubranch;
   Bit#(13) Zbranch;
   Bit#(13) Call;
   struct {
      Bool         r_to_pc;
      Op           op;
      Bool         t_to_n;
      Bool         t_to_r;
      Bool         n_to_mem;
      Reserved#(1) reserved; // same memory layout for unpack()
      StackOff     rstack;
      StackOff     dstack;
      } Alu;
   } DecodedInst deriving (Bits, FShow);

typedef Client#(MemoryRequest#(16, 16), MemoryResponse#(16)) J1Client_IFC;
typedef Server#(MemoryRequest#(16, 16), MemoryResponse#(16)) J1Server_IFC;

(* synthesize *)
module mkJ1(J1Client_IFC);
   Reg#(Bit#(15))                pc     <- mkReg(0); // process counter
   Reg#(Word)                    st0    <- mkRegU;   // top of stack (TOS)
   Reg#(StackPtr)                dsp    <- mkReg(0); // data stack pointer
   Reg#(StackPtr)                rsp    <- mkReg(0); // return stack pointer
   FIFO#(MemoryRequest#(16, 16)) io_req <- mkFIFO;
   FIFO#(MemoryResponse#(16))    io_rsp <- mkFIFO;
   Wire#(Word)                   io_rdata <- mkDWire(?);

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

   /* decode instruction */
   function DecodedInst decode (Word x);
      if (x[15] == 1)
         return tagged Lit x[14:0];
      else
         case (x[14:13])
            2'b00: return tagged Ubranch x[12:0];
            2'b01: return tagged Zbranch x[12:0];
            2'b10: return tagged Call x[12:0];
            2'b11: return tagged Alu unpack(x[12:0]);
         endcase
   endfunction

   /* ALU */
   function Word alu(Op op, Word rdata);
      /* signed stack operands */
      Int#(16) sst0 = unpack(st0);
      Int#(16) sst1 = unpack(st1);

      case (op)
         OP_T          : alu = st0;
         OP_N          : alu = st1;
         OP_T_PLUS_N   : alu = st0 + st1;
         OP_T_AND_N    : alu = st0 & st1;
         OP_T_IOR_N    : alu = st0 | st1;
         OP_T_XOR_N    : alu = st0 ^ st1;
         OP_INV_T      : alu = ~st0;
         OP_N_EQ_T     : alu = (st1 == st0) ? '1 : '0;
         OP_N_LS_T     : alu = (sst1 < sst0) ? '1 : '0;
         OP_N_RSHIFT_T : alu = (st0 > 15) ? 0 : st1 >> st0[3:0];
         OP_T_MINUS_1  : alu = st0 - 1;
         OP_R          : alu = rst0;
         OP_AT         : alu = rdata;
         OP_N_LSHIFT_T : alu = (st0 > 15) ? 0 : st1 << st0[3:0];
         OP_DEPTH      : alu = {3'b0, rsp, 3'b0, dsp};
         OP_N_ULS_T    : alu = (st1 < st0) ? '1 : '0;
         default         alu = ?;
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
      Bool wen = False;
      Bool ren = False;

      case (opcode) matches
         tagged Lit .value:
            begin
               _dsp = dsp + 1;
               dstack.upd(_dsp, st0);
               _st0 = {1'b0, value};
               _pc  = pc + 2;
            end

         tagged Ubranch .target:
            begin
               _pc = zeroExtend({target, 1'b0});
            end

         tagged Zbranch .target:
            begin
               _dsp = dsp - 1; // predicated jump is like DROP
               _st0 = st1;
               if (st0 == 0)
                  _pc = zeroExtend({target, 1'b0});
               else
                  _pc = pc + 2;
            end

         tagged Call .target:
            begin
               _rsp = rsp + 1;
               rstack.upd(_rsp, zeroExtend(pc + 2));
               _pc = zeroExtend({target, 1'b0});
            end

         tagged Alu {
                     r_to_pc:  .r_to_pc,
                     op:       .op,
                     t_to_n:   .t_to_n,
                     t_to_r:   .t_to_r,
                     n_to_mem: .n_to_mem,
                     rstack:   .rstk,
                     dstack:   .dstk
                     }:
            begin
               wen = n_to_mem;
               ren = (op == OP_AT) && !wen;

               let rdata = (st0[15:14] == 0) ? ram.b.read : io_rdata;
               _st0 = alu(op, rdata);

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

      ram.a.put(False, _pc[14:1], ?);

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

   rule rl_io_rsp;
      let rsp = io_rsp.first;
      io_rsp.deq;
      io_rdata <= rsp.data;
   endrule

   return toGPClient(io_req, io_rsp);
endmodule

endpackage
