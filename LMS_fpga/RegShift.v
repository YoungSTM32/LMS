module RegShift #(
	parameter N = 8,    // 延迟时钟个数 值域 正整数 
	parameter W = 1,    // 位宽 值域 正整数
	parameter DIR = 0   // 移动方向 值域 {0,1} 0 << 1>>
)(
	input  wire clk,
	input  wire rst,
	input  wire en,
	input  wire [W-1:0] din,
	output reg  [W*N-1:0] d_all = {W*N{1'b0}},
	output wire [W-1:0] dout
);

generate
	if (DIR == 0) begin
		
		always @(posedge clk or posedge rst) begin
			if (rst)
				d_all <= {W*N{1'b0}};
			else if (en)
				d_all <= {d_all[0 +: W*(N-1)],din};
		end
		
		assign dout = d_all[(W*N-1) -: W];

	end
	else begin
		
		always @(posedge clk or posedge rst) begin
			if (rst)
				d_all <= {W*N{1'b0}};
			else if (en)
				d_all <= {din,d_all[(W*N-1) -: (W*(N-1))]};
		end

		assign dout = d_all[0 +: W];

	end

endgenerate

endmodule
