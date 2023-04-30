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
   } DecodedInst deriving (Bits, Eq, FShow);

typedef MemoryRequest#(16, 16) IORequest;
typedef MemoryResponse#(16)    IOResponse;

typedef Client#(IORequest, IOResponse) J1Client_IFC;
typedef Server#(IORequest, IOResponse) J1Server_IFC;

endpackage
