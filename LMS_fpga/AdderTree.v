module AdderTree #(
	parameter DATA_W = 16,
	parameter DATA_N = 10,
	localparam EXT_W = clogb2(DATA_N),
	localparam SUM_W = DATA_W + EXT_W
)(
	input  wire clk,
	input  wire rst,
	input  wire [DATA_W*DATA_N-1:0] dataIn,
	output reg  [SUM_W-1:0] sumOut
);

`include "clogb2.vh"

localparam GROUP_A_N = 2**(EXT_W-1);              // 分为两组，第一组满2**n
localparam GROUP_B_N = DATA_N - GROUP_A_N;
localparam SUM_A_W = DATA_W + clogb2(GROUP_A_N);  // 第一组结果位宽
localparam SUM_B_W = DATA_W + clogb2(GROUP_B_N);  // 第二组结果位宽
localparam SUM_AB_SUB = SUM_A_W - SUM_B_W;		  // 两位宽只差，用于判断延迟级数

generate
	if (DATA_N <= 1) begin     // 直接输出，千万不要延迟
		always @(*) begin
			if (rst) begin
				sumOut <= {SUM_W{1'b0}};
			end
			else begin
				sumOut <= dataIn;	
			end
		end
	end
	else if(DATA_N == 2) begin // 当加数为2时，为迭代的终点，此时两个数直接扩位相加即可
		always @(posedge clk or posedge rst) begin
			if (rst) begin
				sumOut <= {SUM_W{1'b0}};
			end
			else begin
				sumOut <= {dataIn[DATA_W-1],dataIn[(DATA_W-1)-:DATA_W]}     + 
				          {dataIn[DATA_W*2-1],dataIn[(DATA_W*2-1)-:DATA_W]} ;	
			end
		end
	end
	else begin // 加数大于2时，若个数为双，分两组迭代相加，否则，一组补零后再迭代相加
		
		wire [SUM_A_W-1:0]Sum_A;
		AdderTree #(
			.DATA_W(DATA_W),
			.DATA_N(GROUP_A_N)
		)u_AdderTree_A(
			.clk(clk),
			.rst(rst),
			.dataIn(dataIn[0+:GROUP_A_N*DATA_W]),
			.sumOut(Sum_A));

		wire [SUM_B_W-1:0]Sum_B;
		AdderTree #(
			.DATA_W(DATA_W),
			.DATA_N(GROUP_B_N)
		)u_AdderTree_B(
			.clk(clk),
			.rst(rst),
			.dataIn(dataIn[GROUP_A_N*DATA_W +:GROUP_B_N*DATA_W]),
			.sumOut(Sum_B));			

		if(SUM_AB_SUB == 0) begin
			always @(posedge clk or posedge rst) begin
				if (rst) begin
					sumOut <= {SUM_W{1'b0}};
				end
				else begin
					sumOut <= { {(SUM_W-SUM_A_W){Sum_A[SUM_A_W-1]}},Sum_A} + 
							  { {(SUM_W-SUM_B_W){Sum_B[SUM_B_W-1]}},Sum_B} ;	
				end
			end
		end
		else if(SUM_AB_SUB == 1) begin
			reg [SUM_B_W-1:0]Sum_B_dly;
			always @(posedge clk or posedge rst)begin
				if (rst) begin
					Sum_B_dly <= {SUM_B_W{1'b0}};
					sumOut <= {SUM_W{1'b0}};
				end
				else begin
					Sum_B_dly <= Sum_B;
					sumOut <= { {(SUM_W-SUM_A_W){Sum_A[SUM_A_W-1]}},Sum_A}                      + 
							  { {(SUM_W-SUM_B_W){Sum_B_dly[SUM_B_W-1]}},Sum_B_dly[SUM_B_W-1:0]} ; 		
				end
			end
		end
		else begin
			reg [SUM_B_W*SUM_AB_SUB-1:0]Sum_B_dly;
			always @(posedge clk or posedge rst)begin
				if (rst) begin
					Sum_B_dly <= {(SUM_B_W*SUM_AB_SUB){1'b0}};
					sumOut <= {SUM_W{1'b0}};
				end
				else begin
					Sum_B_dly <= {Sum_B,Sum_B_dly[SUM_B_W +: (SUM_AB_SUB-1)*SUM_B_W]};
					sumOut <= { {(SUM_W-SUM_A_W){Sum_A[SUM_A_W-1]}},Sum_A}                      + 
							  { {(SUM_W-SUM_B_W){Sum_B_dly[SUM_B_W-1]}},Sum_B_dly[SUM_B_W-1:0]} ;		
				end
			end
		end

	end
endgenerate

endmodule
