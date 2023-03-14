`timescale 1ns/1ps
module tb ();
reg clk;
reg rst;
reg signed [15:0] data_in;
reg signed [15:0] data_ref;
wire signed [15:0] error;
wire signed [15:0] data_out;
 
integer fpr_s_addnoise;
integer fpr_s;
integer count1;
integer count2;
integer  i;
 //data_in与data_ref标红，需要初始化给初值。
initial
begin
	$display("step1:Load  Data");
	fpr_s_addnoise = $fopen("s_addnoise.txt","r");
	fpr_s = $fopen("s.txt","r");
	$display("step2:Write Data to LMS_Filter");
	for(i = 0; i <= 17'd131071; i = i + 1) begin
  		count1 = $fscanf(fpr_s_addnoise,"%d",data_in);
  		count2 = $fscanf(fpr_s,"%d",data_ref);
  		#10;
  	end
  	$finish();
end

initial
begin
    data_in<=16'h00;
    data_ref<=16'h00;
	clk = 1'b0;
	rst = 1'b1;
	#50 rst = 1'b0;	
end
always #5 clk = ~clk;

LMS #(
	.DAT_W(16),
	.STEP(48),
	.TAP(63)
)u_LMS(
	.clk(clk), 
	.rst(rst),
	.dataIn(data_in),
	.refIn(16'd0),
	.isOutRef(1'b0),
	.dataOut(data_out)

);

initial 
begin
	$dumpfile("tb.vcd"); 
	$dumpvars; 
end

endmodule
