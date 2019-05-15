#!/usr/bin/perl -W
#FileName:	gen_fifo.pl
#Function:
#		gen FIFO rtl for spec deepth,data format
#Parameter:
#		$1:data_format_file
#		$2:FIFO deepth	
#		$3:write clock 0/1 
#		$4:read clock  0/1
#		$5:clock relation 0/1
#ParameterStatement:
#		data_format_file
#			DataSignal:BitWidth
#		the relation between of write clock and read clock 
#			big indicate faster
#		clock relation 
#			0:Sync
#			1:Async
#
		
`rm -f fifo.v`;
open OUTFILE,">fifo.v";
my @DataSignalName;
my @DataSignalWidth; 
my @argv = @ARGV;

my $datafmtfile=$argv[0];
my $fifosize=$argv[1];
my $rdclk=$argv[2];
my $wrclk=$argv[3];
my $clkrltn=$argv[4];
print "gen_fifo $datafmtfile $fifosize $rdclk $wrclk $clkrltn\n";
open FORMATFILE,"<$datafmtfile";
my $data_count=0;
while(<FORMATFILE>)
{
	if(/(.*):(\d*)/)
	{
		push(@DataSignalName,$1);
		push(@DataSignalWidth,$2);
		print "a data:$1,$2\n";
		$data_count = $data_count+1; 
	}
}

##spec the fast clock and slow clock  
my $fastclock = "clock";
my $slowclock = "clock";
if($rdclk > $wrclk)
{	
	$fastclock = "rd_clock";
	$slowclock = "wr_clock";
}
else{ 
if ($rdclk < $wrclk)
{
	$fastclock = "wr_clock";
	$slowclock = "rd_clock";
}
}
##gen the verilog code 

#IO Port 
print OUTFILE "module fifo(\n";
print OUTFILE "input $fastclock,\n";
if($rdclk != $wrclk)
{
print OUTFILE "input $slowclock,\n";
}
print OUTFILE "input rst_n,\n";
print OUTFILE "input wr_en,\n";
print OUTFILE "input rd_en,\n";
for($i=0;$i < $data_count;$i++)
{
my $bitWidth = $DataSignalWidth[$i]-1;
my $signal = $DataSignalName[$i];
print OUTFILE "input \[$bitWidth:0\] wr_$signal,\n";
}
for($i=0;$i < $data_count;$i++)
{
my $bitWidth = $DataSignalWidth[$i]-1;
my $signal = $DataSignalName[$i];
print OUTFILE "output \[$bitWidth:0\] rd_$signal,\n";
}

print OUTFILE "output empty,\n";
print OUTFILE "output full\n";
print OUTFILE ");\n";

#define signal shift_wr_en
#define signal shift_rd_en 
print OUTFILE "wire shift_wr_en;\n";
print OUTFILE "wire shift_rd_en;\n";
#data shift reg 
for($i=0;$i<$data_count;$i++)
{
my $data_width = $DataSignalWidth[$i];
my $width = $data_width * $fifosize;
my $bitWidth = $width-1;
my $signal = $DataSignalName[$i];
print OUTFILE "reg \[$bitWidth:0\] $signal\_shift_r;\n";
print OUTFILE "wire \[$bitWidth:0\] $signal\_shift_pre;\n";

print OUTFILE "always\@(posedge $fastclock or negedge rst_n)\n";
print OUTFILE "\tif\(!rst_n\)\n";
print OUTFILE "\t\t$signal\_shift_r <= $width\'b0;\n";
print OUTFILE "\telse\n";
print OUTFILE "\t\t$signal\_shift_r <= $signal\_shift_pre;\n";

print OUTFILE "assign $signal\_shift_pre = shift_wr_en ? \{$signal\_shift_pre\[$bitWidth:$data_width\],wr_$signal\}:\n";
print OUTFILE "\t\t$signal\_shift_r;\n";
}

#cursor shift reg 
my $cur_width = $fifosize+1 ;
my $cur_sr = $fifosize-1;
print OUTFILE "reg [$fifosize:0] cur_shift_r;\n";
print OUTFILE "wire [$fifosize:0] cur_shift_pre;\n";

print OUTFILE "always\@(posedge $fastclock or negedge rst_n)\n";
print OUTFILE "\tif\(!rst_n\)\n";
print OUTFILE "\t\tcur_shift_r <= $cur_width\'b0;\n";
print OUTFILE "\telse\n";
print OUTFILE "\t\tcur_shift_r <= cur_shift_pre;\n";

print OUTFILE "assign cur_shift_pre = \(cur_shift_r == $cur_width\'b0\) ? $cur_width\'b1 :\n";
print OUTFILE "\t\tshift_wr_en & ~shift_rd_en ? \{cur_shift_r\[$cur_sr:0\],1\'b0\} :\n";
print OUTFILE "\t\tshift_rd_en & ~shift_wr_en ? \{1\'b0,cur_shift_r\[$fifosize:1\]\} :\n";
print OUTFILE "\t\t$cur_width\'b1;\n";

#output data 
for( $i=0 ; $i< $data_count ;$i++){
$data_signal = $DataSignalName[$i];
$data_width  = $DataSignalWidth[$i];
print OUTFILE "assign rd_$data_signal = \n ";

for($j=1 ; $j<= $fifosize;$j++){
$current_index = ($j-1)*$data_width;
$next_index = $j*$data_width-1 ;
print OUTFILE "\tcur_shift_r[$j] ? $data_signal\_shift_r[$next_index:$current_index] :\n";
}
print OUTFILE "\t$data_width\'b0 ;\n";
}
if($rdclk != $wrclk){
#1.devide
print OUTFILE "reg clk_div;\n"; 
print OUTFILE "always\@\(posedge $slowclock or negedge rst_n\)\n";
print OUTFILE "if\(!rst_n\)\n";
print OUTFILE "\tclk_div <= 1\'b0;\n";
print OUTFILE "else\n";
print OUTFILE "\tclk_div <= ~clk_div;\n";
#2.delay a fastclock
print OUTFILE "reg clk_div_d ;\n";
print OUTFILE "always\@\(posedge $fastclock or negedge rst_n\)\n";
print OUTFILE "if\(!rst_n\)\n";
print OUTFILE "\tclk_div_d <= 1\'b0;\n";
print OUTFILE "else\n";
print OUTFILE "\tclk_div_d <= clk_div;\n";
#slow enable 
print OUTFILE "wire slow_en;\n";
print OUTFILE "assign slow_en = clk_div ^ clk_div_d;\n";

}
#empty & full signal
if($rdclk > $wrclk)
{
print OUTFILE "assign empty = cur_shift_r[0];\n";
print OUTFILE "reg fifo_full_r;\n";
print OUTFILE "wire fifo_full_pre;\n";
print OUTFILE "always\@\(posedge $fastclock or negedge rst_n\)\n";
print OUTFILE "if\(!rst_n\)\n";
print OUTFILE "\tfifo_full_r <= 1'b0;\n";
print OUTFILE "else\n";
print OUTFILE "\tfifo_full_r <= fifo_full_pre;\n";
$temp = $fifosize - 1 ;
print OUTFILE "assign fifo_full_pre = shift_wr_en & ~shift_rd_en & cur_shift_r[$temp] ? 1'b1 : \n";
print OUTFILE "\t\t~cur_shift_r[$fifosize] & slow_en ? 1'b0 : \n";
print OUTFILE "\t\tfifo_full_r;\n";
print OUTFILE "assign full = fifo_full_r;\n";
	
}
else {
if($rdclk < $wrclk)
{
print OUTFILE "assign full = cur_shift_r\[$fifosize\];\n";
print OUTFILE "reg fifo_empty_r;\n";
print OUTFILE "wire fifo_empty_pre;\n";
print OUTFILE "always\@\(posedge $fastclock or negedge rst_n\)\n";
print OUTFILE "if\(!rst_n\)\n";
print OUTFILE "\tfifo_empty_r <= 1'b0;\n";
print OUTFILE "else\n";
print OUTFILE "\tfifo_empty_r <= fifo_empty_pre;\n";
$temp = $fifosize - 1 ;
print OUTFILE "assign fifo_empty_pre = ~shift_wr_en & shift_rd_en & cur_shift_r[1] ? 1'b1 : \n";
print OUTFILE "\t\t~cur_shift_r[0] & slow_en ? 1'b0 : \n";
print OUTFILE "\t\tfifo_empty_r;\n";
print OUTFILE "assign empty = fifo_empty_r;\n";

}
else
{
print OUTFILE "assign empty = cur_shift_r[0];\n";
print OUTFILE "assign full = cur_shift_r\[$fifosize\];\n";
}
}
#write & read en 
if($rdclk > $wrclk)
{
print OUTFILE "assign shift_wr_en = wr_en & slow_en ;\n";
print OUTFILE "assign shift_rd_en = rd_en ;\n";
}
else {
if($rdclk < $wrclk)
{
print OUTFILE "assign shift_wr_en = wr_en ;\n";
print OUTFILE "assign shift_rd_en = rd_en & slow_en ;\n";

}
else 
{
print OUTFILE "assign shift_wr_en = wr_en ;\n";
print OUTFILE "assign shift_rd_en = rd_en ;\n";

}
}
print OUTFILE "endmodule\n";
close OUTFILE; 
close FORMATFILE;
