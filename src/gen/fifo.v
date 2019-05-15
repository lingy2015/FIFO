module fifo(
input clock,
input rst_n,
input wr_en,
input rd_en,
input [3:0] wr_axi_aw_bits_id,
input [31:0] wr_axi_aw_bits_addr,
input [2:0] wr_axi_aw_bits_size,
output [3:0] rd_axi_aw_bits_id,
output [31:0] rd_axi_aw_bits_addr,
output [2:0] rd_axi_aw_bits_size,
output empty,
output full
);
wire shift_wr_en;
wire shift_rd_en;
reg [31:0] axi_aw_bits_id_shift_r;
wire [31:0] axi_aw_bits_id_shift_pre;
always@(posedge clock or negedge rst_n)
	if(!rst_n)
		axi_aw_bits_id_shift_r <= 32'b0;
	else
		axi_aw_bits_id_shift_r <= axi_aw_bits_id_shift_pre;
assign axi_aw_bits_id_shift_pre = shift_wr_en ? {axi_aw_bits_id_shift_pre[31:4],wr_axi_aw_bits_id}:
		axi_aw_bits_id_shift_r;
reg [255:0] axi_aw_bits_addr_shift_r;
wire [255:0] axi_aw_bits_addr_shift_pre;
always@(posedge clock or negedge rst_n)
	if(!rst_n)
		axi_aw_bits_addr_shift_r <= 256'b0;
	else
		axi_aw_bits_addr_shift_r <= axi_aw_bits_addr_shift_pre;
assign axi_aw_bits_addr_shift_pre = shift_wr_en ? {axi_aw_bits_addr_shift_pre[255:32],wr_axi_aw_bits_addr}:
		axi_aw_bits_addr_shift_r;
reg [23:0] axi_aw_bits_size_shift_r;
wire [23:0] axi_aw_bits_size_shift_pre;
always@(posedge clock or negedge rst_n)
	if(!rst_n)
		axi_aw_bits_size_shift_r <= 24'b0;
	else
		axi_aw_bits_size_shift_r <= axi_aw_bits_size_shift_pre;
assign axi_aw_bits_size_shift_pre = shift_wr_en ? {axi_aw_bits_size_shift_pre[23:3],wr_axi_aw_bits_size}:
		axi_aw_bits_size_shift_r;
reg [8:0] cur_shift_r;
wire [8:0] cur_shift_pre;
always@(posedge clock or negedge rst_n)
	if(!rst_n)
		cur_shift_r <= 9'b0;
	else
		cur_shift_r <= cur_shift_pre;
assign cur_shift_pre = (cur_shift_r == 9'b0) ? 9'b1 :
		shift_wr_en & ~shift_rd_en ? {cur_shift_r[7:0],1'b0} :
		shift_rd_en & ~shift_wr_en ? {1'b0,cur_shift_r[8:1]} :
		9'b1;
assign rd_axi_aw_bits_id = 
 	cur_shift_r[1] ? axi_aw_bits_id_shift_r[3:0] :
	cur_shift_r[2] ? axi_aw_bits_id_shift_r[7:4] :
	cur_shift_r[3] ? axi_aw_bits_id_shift_r[11:8] :
	cur_shift_r[4] ? axi_aw_bits_id_shift_r[15:12] :
	cur_shift_r[5] ? axi_aw_bits_id_shift_r[19:16] :
	cur_shift_r[6] ? axi_aw_bits_id_shift_r[23:20] :
	cur_shift_r[7] ? axi_aw_bits_id_shift_r[27:24] :
	cur_shift_r[8] ? axi_aw_bits_id_shift_r[31:28] :
	4'b0 ;
assign rd_axi_aw_bits_addr = 
 	cur_shift_r[1] ? axi_aw_bits_addr_shift_r[31:0] :
	cur_shift_r[2] ? axi_aw_bits_addr_shift_r[63:32] :
	cur_shift_r[3] ? axi_aw_bits_addr_shift_r[95:64] :
	cur_shift_r[4] ? axi_aw_bits_addr_shift_r[127:96] :
	cur_shift_r[5] ? axi_aw_bits_addr_shift_r[159:128] :
	cur_shift_r[6] ? axi_aw_bits_addr_shift_r[191:160] :
	cur_shift_r[7] ? axi_aw_bits_addr_shift_r[223:192] :
	cur_shift_r[8] ? axi_aw_bits_addr_shift_r[255:224] :
	32'b0 ;
assign rd_axi_aw_bits_size = 
 	cur_shift_r[1] ? axi_aw_bits_size_shift_r[2:0] :
	cur_shift_r[2] ? axi_aw_bits_size_shift_r[5:3] :
	cur_shift_r[3] ? axi_aw_bits_size_shift_r[8:6] :
	cur_shift_r[4] ? axi_aw_bits_size_shift_r[11:9] :
	cur_shift_r[5] ? axi_aw_bits_size_shift_r[14:12] :
	cur_shift_r[6] ? axi_aw_bits_size_shift_r[17:15] :
	cur_shift_r[7] ? axi_aw_bits_size_shift_r[20:18] :
	cur_shift_r[8] ? axi_aw_bits_size_shift_r[23:21] :
	3'b0 ;
assign empty = cur_shift_r[0];
assign full = cur_shift_r[8];
assign shift_wr_en = wr_en ;
assign shift_rd_en = rd_en ;
endmodule
