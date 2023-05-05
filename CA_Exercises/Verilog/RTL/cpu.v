//Module: CPU
//Function: CPU is the top design of the RISC-V processor

//Inputs:
//	clk: main clock
//	arst_n: reset 
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[63:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[63:0]  rdata_ext_2

   );

wire              zero_flag;


wire [      63:0] updated_pc;
wire [      63:0] current_pc;
wire [      63:0] jump_pc;


 
//Control Unit Outputs
wire           reg_dst;
wire           branch;
wire           mem_read;
wire           mem_2_reg;
wire           mem_write;
wire           alu_src;
wire           reg_write;
wire           jump;
wire [       1:0] alu_op;

// REG IFID outputs
wire  [63:0]   decode_pc;//from ID to EX
wire [31:0]    instruction_IF_ID;

// REG IDEX outputs
wire  [9:0 ]   Reg_CU_out;
wire  [63:0]   execute_pc_input;//from ID to EX
wire  [105:0]  instruction_ID_IX;

// REG EXMEM outputs
wire [      63:0] branch_pc;
wire [      63:0] branch_EXMEM_pc;
wire [5:0]        Reg_EXMEM_out;
wire [37:0]       instruction_EX_MEM;

// REG MEMWB outputs
wire [1:0]     Reg_MEMWB_out;
wire [84:0]    instruction_MEM_WB;

wire [      31:0] instruction;

wire [       3:0] alu_control;
wire [       4:0] regfile_waddr;
wire [      63:0] regfile_wdata,mem_data,alu_out,
                  regfile_rdata_1,regfile_rdata_2,
                  alu_operand_2;

wire signed [63:0] immediate_extended;




//IF Stage Begin ! yeet
pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc ),
   .jump_pc   (jump_pc   ),
   .zero_flag (instruction_EX_MEM[37] ),
   .branch    (Reg_EXMEM_out[5]    ),
   .jump      (Reg_EXMEM_out[0]      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);

sram_BW32 #(
   .ADDR_W(9 )
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ), 
   .rdata_ext(rdata_ext     ) //read
);
// IF Stage End




//IF_ID Reg Begin
//PC Reg
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)pc_pipe_IF_ID(
   .clk (clk),
   .arst_n (arst_n),
   .din (updated_pc),
   .en(enable),
   .dout(decode_pc)
);
//Instruction reg
reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_IF_ID(
   .clk (clk),
   .arst_n (arst_n),
   .din (instruction),
   .en(enable),
   .dout(instruction_IF_ID)
);
//IF_ID Reg End




//ID Stage Begin
control_unit control_unit(
   .opcode   (instruction_IF_ID[6:0]),
   .alu_op   (aluimmediate_extended_op          ),
   .reg_dst  (reg_dst         ),
   .branch   (branch          ),
   .mem_read (mem_read        ),
   .mem_2_reg(mem_2_reg       ),
   .mem_write(mem_write       ),
   .alu_src  (alu_src         ),
   .reg_write(reg_write       ),
   .jump     (jump            )
);

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(Reg_MEMWB_out[0]         ),
   .raddr_1  (instruction_IF_ID[19:15]),
   .raddr_2  (instruction_IF_ID[24:20]),
   .waddr    (instruction_MEM_WB[4:0] ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_rdata_1   ),
   .rdata_2  (regfile_rdata_2   )
);

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_IF_ID),
    .immediate_extended  (immediate_extended)
);
// ID Stage End
 



// ID_EX_REG Begin
// Control Reg
reg_arstn_en#(
   .DATA_W(10) // width of the forwarded signal
)control_pipe_ID_EX(
   .clk (clk),
   .arst_n (arst_n),
   .din ({reg_dst,branch,mem_read,mem_2_reg,mem_write,alu_src,reg_write,jump,alu_op}),
   .en(enable),
   .dout(Reg_CU_out)
);
// PC Reg
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)pc_pipe_ID_EX(
   .clk (clk),
   .arst_n (arst_n),
   .din (decode_pc),
   .en(enable),
   .dout(execute_pc_input)
);
// Instruction Reg
reg_arstn_en#(
   .DATA_W(106) // width of the forwarded signal
)signal_pipe_ID_EX(
   .clk (clk),
   .arst_n (arst_n),
   // regfile_rdata_1,regfile_rdata_2,immediate_extended,instruction_IF_ID[30],instruction_IF_ID[25],instruction_IF_ID[14:12],instruction_IF_ID[11:7]
   // from instruction_IF_ID
   .din ({regfile_rdata_1,regfile_rdata_2,immediate_extended,instruction_IF_ID[30],instruction_IF_ID[25],instruction_IF_ID[14:12],instruction_IF_ID[11:7]}),
   .en(enable),
   .dout(instruction_ID_IX)
);
// ID_EX_REG End


// EX STAGE BEGIN
branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (execute_pc_input        ),
   .immediate_extended (instruction_ID_IX[73:10]),
   .branch_pc          (branch_EXMEM_pc         ),
   .jump_pc            (jump_pc           )
);

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (instruction_ID_IX[73:10]),
   .input_b (instruction_ID_IX[89:74]    ),
   .select_a(Reg_CU_out[4]           ),
   .mux_out (alu_operand_2     )
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (instruction_ID_IX[105:90] ),
   .alu_in_1 (alu_operand_2   ),
   .alu_ctrl (alu_control     ),
   .alu_out  (alu_out         ),
   .zero_flag(zero_flag       ),
   .overflow (                )
);

alu_control alu_ctrl(
   .func7_5       (instruction_ID_IX[9]   ),
   .func7_0       (instruction_ID_IX[8]  ),
   .func3          (instruction_ID_IX[7:5]),
   .alu_op         (Reg_CU_out[1:0]             ),
   .alu_control    (alu_control       )
);
//EX STAGE END




//EX_MEM REG BEGIN
// Control Reg
reg_arstn_en#(
   .DATA_W(6) // width of the forwarded signal
)control_pipe_EX_MEM(
   .clk (clk),
   .arst_n (arst_n),
   // branch,mem_read,mem_2_reg,mem_write,reg_write,jump from 
   // reg_dst,branch,mem_read,mem_2_reg,mem_write,alu_src,reg_write,jump,alu_op[1:0] (9:0)
   .din ({Reg_CU_out[8:5],Reg_CU_out[3:2]}), 
   .en(enable),
   .dout(Reg_EXMEM_out)
);
// PC Reg
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)pc_pipe_EX_MEM(
   .clk (clk),
   .arst_n (arst_n),
   .din (branch_EXMEM_pc),
   .en(enable),
   .dout(branch_pc)
);
// Instruction Reg
reg_arstn_en#(
   .DATA_W(38) // width of the forwarded signal
)signal_pipe_EX_MEM(
   .clk (clk),
   .arst_n (arst_n),
   // zero_flag,alu_out,instruction_ID_IX[89:74],instruction_ID_IX[4:0]
   // from regfile_rdata_1,regfile_rdata_2,immediate_extended,instruction_IF_ID[30],instruction_IF_ID[25],instruction_IF_ID[14:12],instruction_IF_ID[11:7] (105:0)
   .din ({zero_flag,alu_out,instruction_ID_IX[89:74],instruction_ID_IX[4:0]}),
   .en(enable),
   .dout(instruction_EX_MEM)
);
//EX_MEM REG END




// MEM STAGE BEGIN
sram_BW64 #(
   .ADDR_W(10)
) data_memory(
   .clk      (clk            ),
   .addr     (instruction_EX_MEM[36:21]        ),
   .wen      (Reg_EXMEM_out[2]      ),
   .ren      (Reg_EXMEM_out[4]       ),
   .wdata    (instruction_EX_MEM[20:5] ),
   .rdata    (mem_data       ),   
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);

// MEM STAGE END




// MEM_WB REG BEGIN
// Control Reg
reg_arstn_en#(
   .DATA_W(2) // width of the forwarded signal
)control_pipe_MEM_WB(
   .clk (clk),
   .arst_n (arst_n),
   // mem_2_reg,reg_write
   // from branch,mem_read,mem_2_reg,mem_write,reg_write,jump (5:0)
   .din ({Reg_EXMEM_out[3], Reg_EXMEM_out[1]}),
   .en(enable),
   .dout(Reg_MEMWB_out)
);
// Instruction Reg
reg_arstn_en#(
   .DATA_W(85) // width of the forwarded signal
)signal_pipe_MEM_WB(
   .clk (clk),
   .arst_n (arst_n),
   // mem_data,instruction_EX_MEM[36:21],instruction_EX_MEM[4:0]
   // from zero_flag,alu_out,instruction_ID_IX[89:74],instruction_ID_IX[4:0] (37:0)
   .din ({mem_data,instruction_EX_MEM[36:21],instruction_EX_MEM[4:0]}),
   .en(enable),
   .dout(instruction_MEM_WB)
);
// MEM_WB REG END




// WB STAGE BEGIN
mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (instruction_MEM_WB[84:21]     ),
   .input_b  (instruction_MEM_WB[20:5]      ),
   .select_a (Reg_MEMWB_out[1]    ),
   .mux_out  (regfile_wdata)
);
// WB STAGE END

endmodule


