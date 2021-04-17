package Types;

import ClientServer::*;

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
} Op deriving (Bits, Eq);

typedef union tagged {
   Bit#(15) Lit;
   Bit#(13) Ubranch;
   Bit#(13) Zbranch;
   Bit#(13) Call;
   struct {
      Bool     r_to_pc;
      Op       op;
      Bool     t_to_n;
      Bool     t_to_r;
      Bool     n_to_mem;
      Bit#(1)  reserved; // same memory layout for unpack()
      StackOff rstack;
      StackOff dstack;
      } Alu;
   } DecodedInst deriving (Bits);


typedef struct {
   Bool     write;
   Bit#(16) address;
   Word     data;
   } IORequest deriving (Bits);

typedef struct {
   Word     data;
   } IOResponse deriving (Bits);

typedef Client#(IORequest, IOResponse) IOClient;
typedef Server#(IORequest, IOResponse) IOServer;

endpackage
