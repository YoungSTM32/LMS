module SignedMutiplier #(
	parameter A_W = 8,
	parameter B_W = 8,
	parameter R_W = 16,		      // 如果要cut，注意这里
	parameter CUT_SIGNED_BIT = 0  // 截去的高位个数；=1时，截去1bit符号位；
								  // 此时a和b不能同时为最大负值，否则会出错
)(
	input  wire clk,
	input  wire rst,
	input  wire signed [A_W-1:0] a,
	input  wire signed [B_W-1:0] b,
	output reg  signed [R_W-1:0] result
);

wire signed [A_W+B_W-1:0] mult_out;
assign mult_out = a * b;

always @(posedge clk or posedge rst) begin
	if (rst) begin
		result <= {R_W{1'b0}};
	end
	else begin
		result <= mult_out[(A_W+B_W-1-CUT_SIGNED_BIT) -: R_W];
	end
end

endmodule
