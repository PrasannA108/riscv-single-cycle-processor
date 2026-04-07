//Program Counter
module Program_counter(clk, reset, pc_in, pc_out) ;
    input clk, reset;
    input [31:0] pc_in;
    output reg [31:0] pc_out;

    always@(posedge clk or posedge reset)
    begin
        if(reset)
        pc_out <= 32'b00;
        else
        pc_out <= pc_in;
    end
endmodule

//Counter+4
module Counter(frompc, nextopc);
    input [31:0] frompc;
    output [31:0] nextopc;
    assign nextopc = 4+frompc;
endmodule

//Insruction Memory
module Instruction_Memory(clk, reset, read_address, instruction_out);
    input clk, reset;
    input [31:0] read_address;
    output reg [31:0] instruction_out; // Changed to reg output

    reg [31:0] IMemory[63:0];
    integer k;

    // Initialize memory with instructions
    initial begin
        // Initialize all to zero first
        for(k = 0; k<64; k = k+1) begin
            IMemory[k] = 32'b0;
        end

        // R-type instructions (opcode: 0110011)
        IMemory[4] = 32'b0000000_11001_10000_000_01101_0110011; // add x13, x16, x25
        // Bits: [31:25]=funct7, [24:20]=rs2, [19:15]=rs1, [14:12]=funct3, [11:7]=rd, [6:0]=opcode

        IMemory[8] = 32'b0100000_00011_01000_000_00101_0110011; // sub x5, x8, x3

        IMemory[12] = 32'b0000000_00011_00010_111_00001_0110011; // and x1, x2, x3

        IMemory[16] = 32'b0000000_00101_00011_110_00100_0110011; // or x4, x3, x5

        // I-type ALU (opcode: 0010011)
        IMemory[20] = 32'b000000000011_10101_000_10110_0010011; // addi x22, x21, 3

        IMemory[24] = 32'b000000000001_01000_110_01001_0010011; // ori x9, x8, 1

        // I-type Load (opcode: 0000011)
        IMemory[28] = 32'b000000001111_00101_010_01000_0000011; // lw x8, 15(x5)

        IMemory[32] = 32'b000000000011_00011_010_01001_0000011; // lw x9, 3(x3)

        // S-type Store (opcode: 0100011)
        IMemory[36] = 32'b0000000_01111_00101_010_01100_0100011; // sw x15, 12(x5)
        // Bits: [31:25]=imm[11:5], [24:20]=rs2, [19:15]=rs1, [14:12]=funct3, [11:7]=imm[4:0]

        IMemory[40] = 32'b0000000_01110_00110_010_01010_0100011; // sw x14, 10(x6)

        // SB-type Branch (opcode: 1100011)
        IMemory[44] = 32'b0000000_01001_01001_000_1100_0_1100011; // beq x9, x9, 12
        // Hex: 32'h00948663
    end

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            instruction_out <= 32'b0;
        end
        else begin
            // Byte-addressed memory, but we're using word addressing (divide by 4)
            // Since instructions are 4-byte aligned
            instruction_out <= IMemory[read_address[31:2]]; // Use word address
        end
    end
endmodule

//Register
module Reg(clk, reset, Regwrite, Rs1, Rs2, Rd, Write_data, read_data1, read_data2);
    input clk, reset, Regwrite;
    input [4:0] Rs1, Rs2, Rd;
    input [31:0] Write_data;
    output [31:0] read_data1, read_data2;
    reg [31:0] Registers[32:0];
    initial begin
        Registers[0] = 0;
        Registers[1] = 4;
        Registers[2] = 6;
        Registers[3] = 3;
        Registers[4] = 3;
        Registers[5] = 4;
        Registers[6] = 1;
        Registers[7] = 3;
        Registers[8] = 6;
        Registers[9] = 4;
        Registers[10] = 9;
        Registers[11] = 2;
        Registers[12] = 11;
        Registers[13] = 23;
        Registers[14] = 4;
        Registers[15] = 0;
        Registers[16] = 4;
        Registers[17] = 9;
        Registers[18] = 9;
        Registers[19] = 9;
        Registers[20] = 5;
        Registers[21] = 2;
        Registers[22] = 2;
        Registers[23] = 2;
        Registers[24] = 3;
        Registers[25] = 5;
        Registers[26] = 9;
        Registers[27] = 8;
        Registers[28] = 7;
        Registers[29] = 4;
        Registers[30] = 5;
        Registers[31] = 11;
    end
    integer k;

    always @(posedge clk or posedge reset)
    begin
        if(reset)
        begin
            for(k = 0;k<32;k = k+1)begin
            Registers[k] <= 32'b00;
        end
    end
    else if(Regwrite)begin
    Registers[Rd] <= Write_data;
end
end
assign read_data1 = Registers[Rs1];
assign read_data2 = Registers[Rs2];
endmodule

//Immediate Generator
module Imm(Opcode, instruction, Immext);
    input [6:0] Opcode;
    input [31:0] instruction;
    output reg [31:0] Immext;

    always @(*) begin
        case(Opcode)
            7'b0010011: // I-type ALU (ADDI, ORI, etc.)
            Immext = {{20{instruction[31]}}, instruction[31:20]};

            7'b0000011: // I-type Load (LW)
            Immext = {{20{instruction[31]}}, instruction[31:20]};

            7'b0100011: // S-type Store (SW)
            Immext = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            7'b1100011: // SB-type Branch (BEQ)
            Immext = {{20{instruction[31]}}, instruction[31],
            instruction[30:25], instruction[11:8], 1'b0};

            default:
            Immext = 32'b0;
        endcase
    end
endmodule

//Control Unit
module Control_unit(instruction, branch, memread, memtoreg, ALUOP, memwrite, ALUSRC, regwrite);
    input[6:0] instruction;
    output reg branch, memread, memtoreg, memwrite, ALUSRC, regwrite;
    output reg [1:0] ALUOP;

    always @(*)
    begin
        case(instruction)
            7'b0110011:{ALUSRC,memtoreg,regwrite,memread,memwrite,branch,ALUOP} <= 8'b001000_01;
            7'b0000011:{ALUSRC,memtoreg,regwrite,memread,memwrite,branch,ALUOP} <= 8'b111100_00;
            7'b0100011:{ALUSRC,memtoreg,regwrite,memread,memwrite,branch,ALUOP} <= 8'b100010_00;
            7'b1100011:{ALUSRC,memtoreg,regwrite,memread,memwrite,branch,ALUOP} <= 8'b000001_01;
        endcase
    end
endmodule


//ALU
module ALU(A, B, Control_in, Result, zero);
    input [31:0] A, B;
    input [3:0] Control_in;
    output reg zero;
    output reg [31:0] Result;

    always @(*)
    begin
        case(Control_in)
            4'b0000:begin zero <= 0; Result <= A & B;end
            4'b0001:begin zero <= 0; Result <= A | B;end
            4'b0010:begin zero <= 0; Result <= A + B;end
            4'b0110:begin if(A == B) zero <= 1; else zero <= 0; Result <= A - B; end
        endcase
    end
endmodule

//ALU CONTROL
module ALU_CTRL(ALUOP, fun7, fun3, Control_out);
    input fun7;
    input [2:0] fun3;
    input [1:0] ALUOP;
    output reg [3:0] Control_out;

    always @(*) begin
        case({ALUOP, fun3})
            // I-type & Load/Store: ALUOP=00, always ADD for address calculation
            5'b00_000: Control_out <= 4'b0010; // ADD for lw/sw

            // SB-type (Branch): ALUOP=01, always SUB for comparison
            5'b01_000: Control_out <= 4'b0110; // SUB for beq

            // R-type: ALUOP=10, decode funct7 & funct3
            5'b10_000: begin // ADD or SUB based on fun7
                if (fun7 == 1'b0)
                Control_out <= 4'b0010; // ADD (funct7=0000000)
                else
                Control_out <= 4'b0110; // SUB (funct7=0100000)
            end
            5'b10_111: Control_out <= 4'b0000; // AND (funct3=111)
            5'b10_110: Control_out <= 4'b0001; // OR (funct3=110)
            default: Control_out <= 4'b0010; // Default to ADD
        endcase
    end
endmodule

//Data Memory
module Data_Memory(clk,reset, memwrite, memread, read_address, write_data, memdata_out);
    input clk, reset, memwrite, memread;
    input [31:0] read_address, write_data;
    output reg [31:0] memdata_out; // Changed to reg for always block

    reg [31:0] D_memory[63:0];
    integer k;

    // Initialize data memory
    initial begin
        for(k = 0; k < 64; k = k + 1) begin
            D_memory[k] = 32'b0;
        end
        // Pre-load some data values for testing
        D_memory[0] = 32'h00000001;
        D_memory[1] = 32'h00000002;
        D_memory[2] = 32'h00000003;
        D_memory[15] = 32'h0000000F; // For lw x8, 15(x5) test
        D_memory[3] = 32'h00000033; // For lw x9, 3(x3) test
    end

    // Synchronous write, asynchronous read
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            // Reset doesn't clear memory, just for simulation control
            // Memory retains values across reset (typical for RAM)
        end
        else if(memwrite) begin
            // Word-aligned access (divide address by 4)
            D_memory[read_address[31:2]] <= write_data;
        end
    end

    // Combinational read
    always @(*) begin
        if (memread) begin
            memdata_out = D_memory[read_address[31:2]];
        end
        else begin
            memdata_out = 32'b0;
        end
    end
endmodule

//Mux
module Mux1(sel1, A1, B1, Mux1_out);
    input sel1;
    input [31:0] A1,B1;
    output [31:0] Mux1_out;
    assign Mux1_out = (sel1 == 1'b0) ? A1:B1;
endmodule

//Mux3
module Mux3(sel3, A3, B3, Mux3_out);
    input sel3;
    input [31:0] A3,B3;
    output [31:0] Mux3_out;
    assign Mux3_out = (sel3 == 1'b0) ? A3:B3;
endmodule

//Mux2
module Mux2(sel2, A2, B2, Mux2_out);
    input sel2;
    input [31:0] A2,B2;
    output [31:0] Mux2_out;
    assign Mux2_out = (sel2 == 1'b0) ? A2:B2;
endmodule

//AND
module AND(branch, zero, and_out);
    input branch, zero;
    output and_out;
    assign and_out = branch&zero;
endmodule

//Adder
module Adder(in1, in2, sum_out);
    input [31:0] in1,in2;
    output [31:0] sum_out;
    assign sum_out = in1+in2;
endmodule

//Instantiation
module RISCV_top(clk, reset);
    input clk,reset;
    wire [31:0] pc_top, instruction_top, rd1_top, rd2_top2, Immext_top, mux1_top, sum_out_top, nextopc_top, pcin_top, address_top, memdata_top, writeback_top;
    wire [1:0] ALUOP_top;
    wire [4:0] control_top;
    wire regwrite_top, ALUSRC_top, zero_top, branch_top, sel2_top, memtoreg_top, memwrite_top, memread_top;

    //Program Counter
    Program_counter PC(.clk(clk), .reset(reset), .pc_in(pcin_top), .pc_out(pc_top));

    //Counter+4
    Counter Count(.frompc(pc_top), .nextopc(nextopc_top));

    //Insruction Memory
    Instruction_Memory Mem(.clk(clk), .reset(reset), .read_address(pc_top), .instruction_out(instruction_top));

    //Register
    Reg Regr(.clk(clk), .reset(reset), .Regwrite(regwrite_top), .Rs1(instruction_top[19:15]), .Rs2(instruction_top[24:20]), .Rd(instruction_top[11:7]), .Write_data(writeback_top), .read_data1(rd1_top), .read_data2(rd2_top2));

    //Immediate Generator
    Imm ImmG(.Opcode(instruction_top[6:0]), .instruction(instruction_top), .Immext(Immext_top));

    //Control Unit
    Control_unit CU(.instruction(instruction_top[6:0]), .branch(branch_top), .memread(memread_top), .memtoreg(memtoreg_top), .ALUOP(ALUOP_top), .memwrite(memwrite_top), .ALUSRC(ALUSRC_top), .regwrite(regwrite_top));

    //ALU
    ALU ALU(.A(rd1_top), .B(mux1_top), .Control_in(control_top), .Result(address_top), .zero(zero_top));

    //ALU CONTROL
    ALU_CTRL ALU_CTRL(.ALUOP(ALUOP_top), .fun7(instruction_top[30]), .fun3(instruction_top[14:12]), .Control_out(control_top));

    //Data Memory
    Data_Memory D_M(.clk(clk),.reset(reset), .memwrite(memwrite_top), .memread(memread_top), .read_address(address_top), .write_data(rd2_top2), .memdata_out(memdata_top));

    //Mux
    Mux1 MUX1(.sel1(ALUSRC_top), .A1(rd2_top2), .B1(Immext_top), .Mux1_out(mux1_top));

    //Mux2
    Mux2 MUX2(.sel2(sel2_top), .A2(nextopc_top), .B2(sum_out_top), .Mux2_out(pcin_top));

    //Mux3
    Mux3 MUX3(.sel3(memtoreg_top), .A3(address_top), .B3(memdata_top), .Mux3_out(writeback_top));

    //AND
    AND AND(.branch(branch_top), .zero(zero_top), .and_out(sel2_top));

    //Adder
    Adder ADD(.in1(pc_top), .in2(Immext_top), .sum_out(sum_out_top));
endmodule
