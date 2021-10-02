//
// Generated by Bluespec Compiler, version 2021.07 (build 4cac6eb)
//
// On Sat Oct  2 11:23:52 CEST 2021
//
//
// Ports:
// Name                         I/O  size props
// RDY_request_put                O     1 const
// response_get                   O    16 const
// RDY_response_get               O     1 const
// CLK                            I     1 clock
// RST_N                          I     1 reset
// request_put                    I    35 unused
// EN_request_put                 I     1 unused
// EN_response_get                I     1 unused
//
// No combinational paths from inputs to outputs
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module mkDummyIO(CLK,
		 RST_N,

		 request_put,
		 EN_request_put,
		 RDY_request_put,

		 EN_response_get,
		 response_get,
		 RDY_response_get);
  input  CLK;
  input  RST_N;

  // action method request_put
  input  [34 : 0] request_put;
  input  EN_request_put;
  output RDY_request_put;

  // actionvalue method response_get
  input  EN_response_get;
  output [15 : 0] response_get;
  output RDY_response_get;

  // signals for module outputs
  wire [15 : 0] response_get;
  wire RDY_request_put, RDY_response_get;

  // ports of submodule io_req
  wire [34 : 0] io_req$D_IN;
  wire io_req$CLR, io_req$DEQ, io_req$ENQ;

  // ports of submodule io_rsp
  wire [15 : 0] io_rsp$D_IN;
  wire io_rsp$CLR, io_rsp$DEQ, io_rsp$ENQ;

  // action method request_put
  assign RDY_request_put = 1'd1 ;

  // actionvalue method response_get
  assign response_get = 16'hAAAA ;
  assign RDY_response_get = 1'd1 ;

  // submodule io_req
  FIFO2 #(.width(32'd35), .guarded(1'd1)) io_req(.RST(RST_N),
						 .CLK(CLK),
						 .D_IN(io_req$D_IN),
						 .ENQ(io_req$ENQ),
						 .DEQ(io_req$DEQ),
						 .CLR(io_req$CLR),
						 .D_OUT(),
						 .FULL_N(),
						 .EMPTY_N());

  // submodule io_rsp
  FIFO2 #(.width(32'd16), .guarded(1'd1)) io_rsp(.RST(RST_N),
						 .CLK(CLK),
						 .D_IN(io_rsp$D_IN),
						 .ENQ(io_rsp$ENQ),
						 .DEQ(io_rsp$DEQ),
						 .CLR(io_rsp$CLR),
						 .D_OUT(),
						 .FULL_N(),
						 .EMPTY_N());

  // submodule io_req
  assign io_req$D_IN = 35'h0 ;
  assign io_req$ENQ = 1'b0 ;
  assign io_req$DEQ = 1'b0 ;
  assign io_req$CLR = 1'b0 ;

  // submodule io_rsp
  assign io_rsp$D_IN = 16'h0 ;
  assign io_rsp$ENQ = 1'b0 ;
  assign io_rsp$DEQ = 1'b0 ;
  assign io_rsp$CLR = 1'b0 ;
endmodule  // mkDummyIO
