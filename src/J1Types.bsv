/* J1 Types */

package J1Types;

import ClientServer::*;
import Memory::*;
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
   } DecodedInst deriving (FShow);

instance Bits#(DecodedInst, 18);
   /* unused */
   function Bit#(18) pack(DecodedInst x);
      return ?;
   endfunction

   function DecodedInst unpack(Bit#(18) x);
      return case (x[15:13])
                3'b000: tagged Ubranch x[12:0];
                3'b001: tagged Zbranch x[12:0];
                3'b010: tagged Call x[12:0];
                3'b011: tagged Alu DecodedInst_$Alu {
                                     r_to_pc:  unpack(x[12]),
                                     op:       unpack(x[11:8]),
                                     t_to_n:   unpack(x[7]),
                                     t_to_r:   unpack(x[6]),
                                     n_to_mem: unpack(x[5]),
                                     reserved: unpack(x[4]),
                                     rstack:   unpack(x[3:2]),
                                     dstack:   unpack(x[1:0])
                                     };
                default tagged Lit x[14:0];
             endcase;
   endfunction
endinstance

typedef Client#(MemoryRequest#(16, 16), MemoryResponse#(16)) J1Client_IFC;
typedef Server#(MemoryRequest#(16, 16), MemoryResponse#(16)) J1Server_IFC;

endpackage
