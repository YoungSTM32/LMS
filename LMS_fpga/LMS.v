module LMS #(
	parameter DAT_W = 16,
	parameter STEP = 48,
	parameter TAP = 31
)(
	input  wire clk,
	input  wire rst,
	input  wire [DAT_W-1:0]dataIn,
	input  wire [DAT_W-1:0]refIn,
	input  wire isOutRef,
	output wire [DAT_W-1:0]dataOut
);
//ÎÄ¼þ°üº¬
`include "clogb2.vh"
localparam COE_W = DAT_W*2;
localparam ADD_EXT = clogb2(TAP);
localparam CAL_DELAY = 1 + ADD_EXT;

wire [(TAP+CAL_DELAY)*DAT_W-1:0]shiftAll;
wire [DAT_W-1:0]shiftEndData;
RegShift #(
	.N(TAP + CAL_DELAY),
	.W(DAT_W),    
	.DIR(0)    
)u_RegShift(
	.clk(clk),
	.rst(rst),
	.en(1'b1),
	.din(dataIn),
	.d_all(shiftAll),
	.dout(shiftEndData)
);

wire [TAP*DAT_W-1:0]shiftDataHead;
wire [TAP*DAT_W-1:0]shiftDataTail;
assign shiftDataHead = shiftAll[        0*DAT_W +: TAP*DAT_W];
assign shiftDataTail = shiftAll[CAL_DELAY*DAT_W +: TAP*DAT_W];

reg [TAP*COE_W-1:0]coeGroup;
wire [TAP*(DAT_W+COE_W)-1:0]convMultiResult;
generate
	genvar i;
	for (i = 0; i < TAP; i = i + 1) begin:convMulti
		SignedMutiplier #(
			.A_W(DAT_W),
			.B_W(COE_W),
			.R_W(DAT_W+COE_W),
			.CUT_SIGNED_BIT(0)
		)uConvMulti_SignedMutiplier(
			.clk(clk),
			.rst(rst),
			.a(shiftDataHead[i*DAT_W +: DAT_W]),
			.b(coeGroup[i*COE_W +: COE_W]),
			.result(convMultiResult[i*(DAT_W+COE_W) +: (DAT_W+COE_W)])
		);
	end
endgenerate
wire [(DAT_W+COE_W+ADD_EXT)-1:0]sumConv;
AdderTree #(
	.DATA_W(DAT_W+COE_W),
	.DATA_N(TAP)
)u_AdderTree(
	.clk(clk),
	.rst(rst),
	.dataIn(convMultiResult),
	.sumOut(sumConv)
);
assign dataOut = sumConv[(DAT_W+COE_W+ADD_EXT-1) -: COE_W];
reg [DAT_W+1-1:0]error;
always @(posedge clk or posedge rst) begin
	if (rst) begin
		error <= {DAT_W{1'b0}};
	end
	else begin
		if(isOutRef)
			error <= {refIn[DAT_W-1],refIn} - {dataOut[DAT_W-1],dataOut};
		else
			error <= {shiftEndData[DAT_W-1],shiftEndData} - {dataOut[DAT_W-1],dataOut};
	end
end
generate
	genvar j;
	for (j = 0; j < TAP; j = j + 1) begin:convUpdate
		wire [DAT_W+DAT_W-1:0]convUpdateTemp;
		SignedMutiplier #(
			.A_W(DAT_W),
			.B_W(DAT_W),
			.R_W(DAT_W+DAT_W),
			.CUT_SIGNED_BIT(0)
		)uConvUpdate_SignedMutiplier(
			.clk(clk),
			.rst(rst),
			.a(shiftDataTail[j*DAT_W +: DAT_W]),
			.b(error[1+:DAT_W]),
			.result(convUpdateTemp)
		);
		always @(posedge clk or posedge rst) begin
			if (rst) begin
				coeGroup[j*COE_W +: COE_W] <= {COE_W{1'b0}};
			end
			else begin
				coeGroup[j*COE_W +: COE_W] <= coeGroup[j*COE_W +: COE_W] + 
					{ {(STEP-COE_W){convUpdateTemp[DAT_W+DAT_W-1]}} , convUpdateTemp[(DAT_W+DAT_W-1) : (STEP-COE_W)] };
			end
		end
	end
endgenerate
endmodule
