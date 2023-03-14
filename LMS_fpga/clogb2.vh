// 基二的并行加法树
// i --> 0 1 2 3 4 
// o --> 0 0 1 2 2
function integer clogb2 (
	input integer depth
);
	integer i;
	begin
		clogb2 = 0;
		for(i = 0; 2**i < depth;i = i + 1)
			clogb2 = i + 1;
	end
endfunction