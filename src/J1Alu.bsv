/* J1 ALU */

package J1Alu;

import J1Types::*;

function Word alu(Op op, Word st0, Word st1, Word rst0, Word rdata, StackPtr dsp, StackPtr rsp);
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
     OP_AT         : alu  = rdata;
     OP_N_LSHIFT_T : alu  = (st0 > 15) ? 0 : st1 << st0[3:0];
     OP_DEPTH      : alu  = {3'b0, rsp, 3'b0, dsp};
     OP_N_ULS_T    : alu  = (st1 < st0) ? '1 : '0;
     default         alu  = ?;
   endcase
endfunction

endpackage
