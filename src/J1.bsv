// http://csg.csail.mit.edu/6.375/6_375_2016_www/handouts/lectures/L09-NonPipelinedProcessors.pdf

package J1;

import BRAMCore::*;
import GetPut::*;
import ClientServer::*;
import RegFile::*;

import Types::*;

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

module mkJ1(IOClient);
   Reg#(Bit#(15))  pc  <- mkReg(0); // process counter
   Reg#(Word)      st0 <- mkRegU;   // top of stack (TOS)
   Reg#(StackPtr)  dsp <- mkReg(0); // data stack pointer
   Reg#(StackPtr)  rsp <- mkReg(0); // return stack pointer

   /* Dual-Port RAM 16Kx16
    *  port a: instruction
    *  port b: data
    */
   BRAM_DUAL_PORT#(RamAddr, Word) ram <- mkBRAMCore2Load(2**14, False, "ram.mem", False);

   /* data stack 32x16 + st0 */
   RegFile#(StackPtr, Word) dstack <- mkRegFileFull;
   let st1 = dstack.sub(dsp); // next of stack (NOS)

   /* return stack 32x16 */
   RegFile#(StackPtr, Word) rstack <- mkRegFileFull;
   let rst0 = rstack.sub(rsp); // top of return stack (TOR)

   rule run;
      /* instruction fetch */
      let insn   = (pc == 0) ? 16'h6000 : ram.a.read; // first instruction must always be a NOOP
      let opcode = decode(insn);

      /* execute */
      let _st0 = st0;
      let _dsp = dsp;
      let _rsp = rsp;
      let  _pc = pc;
      Bool wen = False;

      case (opcode) matches
         tagged Lit .value:
            begin: ex_lit
               _dsp = dsp + 1;
               dstack.upd(_dsp, st0);
               _st0 = {1'b0, value};
               _pc  = pc + 2;
            end: ex_lit

         tagged Ubranch .target:
            begin: ex_ubranch
               _pc = zeroExtend({target, 1'b0});
            end: ex_ubranch

         tagged Zbranch .target:
            begin: ex_zbranch
               _dsp = dsp - 1; // predicated jump is like DROP
               _st0 = st1;
               if (st0 == 0)
                  _pc = zeroExtend({target, 1'b0});
               else
                  _pc = pc + 2;
            end: ex_zbranch

         tagged Call .target:
            begin: ex_call
               _rsp = rsp + 1;
               rstack.upd(_rsp, zeroExtend(pc + 2));
               _pc = zeroExtend({target, 1'b0});
            end: ex_call

         tagged Alu {
                     r_to_pc:  .r_to_pc,
                     op:       .op,
                     t_to_n:   .t_to_n,
                     t_to_r:   .t_to_r,
                     n_to_mem: .n_to_mem,
                     rstack:   .rstk,
                     dstack:   .dstk
                     }:
            begin: ex_alu
               /* signed stack operands */
               Int#(16) sst0 = unpack(st0);
               Int#(16) sst1 = unpack(st1);

               case (op)
                  OP_T          : _st0 = st0;
                  OP_N          : _st0 = st1;
                  OP_T_PLUS_N   : _st0 = st0 + st1;
                  OP_T_AND_N    : _st0 = st0 & st1;
                  OP_T_IOR_N    : _st0 = st0 | st1;
                  OP_T_XOR_N    : _st0 = st0 ^ st1;
                  OP_INV_T      : _st0 = ~st0;
                  OP_N_EQ_T     : _st0 = (st1 == st0) ? '1 : '0;
                  OP_N_LS_T     : _st0 = (sst1 < sst0) ? '1 : '0;
                  OP_N_RSHIFT_T : _st0 = (st0 > 15) ? 0 : st1 >> st0[3:0];
                  OP_T_MINUS_1  : _st0 = st0 - 1;
                  OP_R          : _st0 = rst0;
                  OP_AT         : _st0 = (st0[15:14] == 0) ? ram.b.read : ?; // FIXME: add I/O
                  OP_N_LSHIFT_T : _st0 = (st0 > 15) ? 0 : st1 << st0[3:0];
                  OP_DEPTH      : _st0 = {3'b0, rsp, 3'b0, dsp};
                  OP_N_ULS_T    : _st0 = (st1 < st0) ? '1 : '0;
                  default         _st0 = ?;
               endcase

               wen = n_to_mem;

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
            end: ex_alu
      endcase

      ram.a.put(False, _pc[14:1], ?);

      // FIXME: add I/O
      if (_st0[15:14] == 0)
         ram.b.put(wen, _st0[14:1], st1);

      dsp <= _dsp;
      rsp <= _rsp;
      st0 <= _st0;
      pc  <= _pc;

      $display("%t: pc=%h insn=%h dsp=%h st0=%h st1=%h rsp=%h rst0=%h",
               $time, pc, insn, dsp, st0, st1, rsp, rst0);
   endrule

   interface Get request;
      method ActionValue#(IORequest) get();
         return ?; // FIXME
      endmethod
   endinterface

   interface Put response;
      method Action put(rsp);
      // FIXME
      endmethod
   endinterface

endmodule

endpackage
