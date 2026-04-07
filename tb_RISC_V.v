
module RISCV_TOP_Tb;
reg clk, reset;
RISCV_top UUT (
.clk(clk),
.reset(reset)
);
// clock generation
initial begin
clk=0;
end
always #50 clk=~clk;

// reset
initial begin
reset = 1'b1;
#50;
reset= 1'b0;
#1000;
$finish;
end

endmodule

