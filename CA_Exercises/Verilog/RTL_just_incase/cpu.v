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





// IF
// Instruction memory outputs
wire [      31:0] instruction;

// PC outputs 
wire [      63:0] updated_pc;
wire [      63:0] current_pc;





// REG IFID_PC outputs
wire  [63:0]   ID_pc; // for in ID

// REG IFID_Instruction outputs
wire [31:0]    ID_instruction;





// ID
// Control Unit outputs
wire           reg_dst;
wire           branch;
wire           mem_read;
wire           mem_2_reg;
wire           mem_write;
wire           alu_src;
wire           reg_write;
wire           jump;
wire [       1:0] alu_op;

// Register file outputs
wire [      63:0] regfile_rdata_1,regfile_rdata_2;


// Immediate extended unit outputs
wire signed [63:0] immediate_extended;






// REG IDEX_aluop outputs
wire [       1:0] EX_alu_op;

// REG IDEX_regdst outputs
wire           EX_reg_dst;

// REG IDEX_branch outputs
wire           EX_branch;

// REG IDEX_memread outputs
wire           EX_mem_read;

// REG IDEX_mem2reg outputs
wire           EX_mem_2_reg;

// REG IDEX_memwrite outputs
wire           EX_mem_write;

// REG IDEX_alusrc outputs
wire           EX_alu_src;

// REG IDEX_regwrite outputs
wire           EX_reg_write;

// REG IDEX_jump outputs
wire           EX_jump;

// REG IDEX_PC outputs
wire  [63:0]   EX_pc; // for in EX

// REG IDEX_readdata1 outputs
wire [      63:0] EX_regfile_rdata_1;

// REG IDEX_readdata2 outputs
wire [      63:0] EX_regfile_rdata_2;

// REG IDEX_immediate outputs
wire signed [63:0] EX_immediate_extended;

// REG IDEX_func75 outputs
wire           EX_func75;

// REG IDEX_func70 outputs
wire           EX_func70;

// REG IDEX_func3 outputs
wire [      2:0] EX_func3;

// REG IDEX_waddr outputs
wire [      4:0] EX_waddr;






// EX
// Branch unit outputs
wire [      63:0] branch_pc;
wire [      63:0] jump_pc;

// alu_operand_mux outputs
wire [      63:0] alu_operand_2;

// alu outputs
wire [      63:0] alu_out;
wire              zero_flag;

// alu_ctrl outputs
wire [       3:0] alu_control;

//forwarding unit 
wire [1:0]        ForwardA;
wire [1:0]        ForwardB;

//forwarding multiplexers
//(goes into the ALU and the pervious immediate ALU input)
wire [63:0] alu_mux_forwarding_out_0;
wire [63:0] alu_mux_forwarding_out_1;

//read addresses one and two
wire  [4:0] EX_register_rs1;
wire  [4:0] EX_register_rs2;





// REG EXMEM_Branch outputs
wire   [      63:0]  MEM_branch_pc;

// REG EXMEM_jump outputs
wire   [      63:0]  MEM_jump_pc;

// REG EXMEM_regdst outputs
wire           MEM_reg_dst;

// REG EXMEM_branch outputs
wire           MEM_branch;

// REG EXMEM_memread outputs
wire           MEM_mem_read;

// REG EXMEM_mem2reg outputs
wire           MEM_mem_2_reg;

// REG EXMEM_memwrite outputs
wire           MEM_mem_write;

// REG EXMEM_regwrite outputs
wire           MEM_reg_write;

// REG EXMEM_jump outputs
wire           MEM_jump;

// REG EXMEM_PC outputs
wire  [63:0]   MEM_pc; // for in MEM

// REG EXMEM_zero outputs
wire           MEM_zero_flag;

// REG EXMEM_aluout outputs
wire [      63:0] MEM_alu_out;

// REG EXMEM_readdata2 outputs
wire [      63:0] MEM_regfile_rdata_2;

// REG EXMEM_waddr outputs
wire [      4:0] MEM_waddr;






// MEM
// Data memory outputs
wire [      63:0] MEM_mem_data;






// REG MEMWB_regdst outputs
wire           WB_reg_dst;

// REG MEMWB_mem2reg outputs
wire           WB_mem_2_reg;

// REG MEMWB_regwrite outputs
wire           WB_reg_write;

// REG MEMWB_mem_data outputs
wire [   63:0] WB_mem_data;

// REG MEMWB_aluout outputs
wire [   63:0] WB_alu_out;

// REG MEMWB_waddr outputs
wire [    4:0] WB_waddr;






// WB
// Regfile_data_mux
wire [      63:0] WB_regfile_wdata;








//IF Stage Begin ! yeet
pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk),
   .arst_n    (arst_n),
   .branch_pc (MEM_branch_pc),//use to be branch_pc
   .jump_pc   (MEM_jump_pc),//use to be jump_pc
   .zero_flag (MEM_zero_flag),
   .branch    (MEM_branch),
   .jump      (MEM_jump),// put the the stage earliers program counter
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
   .dout(ID_pc)
);
//Instruction reg
reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_IF_ID(
   .clk (clk),
   .arst_n (arst_n),
   .din (instruction),
   .en(enable),
   .dout(ID_instruction)
);
//IF_ID Reg End









//ID Stage Begin
control_unit control_unit(
   .opcode   (ID_instruction[6:0]),
   .alu_op   (alu_op          ),
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
   .clk      (clk),
   .arst_n   (arst_n),
   .reg_write(WB_reg_write),
   .raddr_1  (ID_instruction[19:15]),
   .raddr_2  (ID_instruction[24:20]),
   .waddr    (WB_waddr),
   .wdata    (WB_regfile_wdata),
   .rdata_1  (regfile_rdata_1   ),
   .rdata_2  (regfile_rdata_2   )
);

immediate_extend_unit immediate_extend_u(
    .instruction         (ID_instruction),
    .immediate_extended  (immediate_extended)
);
// ID Stage End
 








// ID_EX_REG Begin
// REG IDEX_aluop outputs
reg_arstn_en#(
   .DATA_W(2) // width of the forwarded signal
)IDEX_aluop(
   .clk (clk),
   .arst_n (arst_n),
   .din (alu_op),
   .en(enable),
   .dout(EX_alu_op)
);

// REG IDEX_regdst outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)IDEX_regdst(
   .clk (clk),
   .arst_n (arst_n),
   .din (reg_dst),
   .en(enable),
   .dout(EX_reg_dst)
);

// REG IDEX_branch outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)IDEX_branch(
   .clk (clk),
   .arst_n (arst_n),
   .din (branch),
   .en(enable),
   .dout(EX_branch)
);

// REG IDEX_memread outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)IDEX_memread(
   .clk (clk),
   .arst_n (arst_n),
   .din (mem_read),
   .en(enable),
   .dout(EX_mem_read)
);

// REG IDEX_mem2reg outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)IDEX_mem2reg(
   .clk (clk),
   .arst_n (arst_n),
   .din (mem_2_reg),
   .en(enable),
   .dout(EX_mem_2_reg)
);

// REG IDEX_memwrite outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)IDEX_memwrite(
   .clk (clk),
   .arst_n (arst_n),
   .din (mem_write),
   .en(enable),
   .dout(EX_mem_write)
);

// REG IDEX_alusrc outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)IDEX_alusrc(
   .clk (clk),
   .arst_n (arst_n),
   .din (alu_src),
   .en(enable),
   .dout(EX_alu_src)
);

// REG IDEX_regwrite outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)IDEX_regwrite(
   .clk (clk),
   .arst_n (arst_n),
   .din (reg_write),
   .en(enable),
   .dout(EX_reg_write)
);

// REG IDEX_jump outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)IDEX_jump(
   .clk (clk),
   .arst_n (arst_n),
   .din (jump),
   .en(enable),
   .dout(EX_jump)
);

// REG IDEX_PC outputs
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)IDEX_PC(
   .clk (clk),
   .arst_n (arst_n),
   .din (ID_pc),
   .en(enable),
   .dout(EX_pc)
);

// REG IDEX_readdata1 outputs
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)IDEX_readdata1(
   .clk (clk),
   .arst_n (arst_n),
   .din (regfile_rdata_1),
   .en(enable),
   .dout(EX_regfile_rdata_1)
);

// REG IDEX_readdata2 outputs
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)IDEX_readdata2(
   .clk (clk),
   .arst_n (arst_n),
   .din (regfile_rdata_2),
   .en(enable),
   .dout(EX_regfile_rdata_2)
);

// REG IDEX_immediate outputs
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)IDEX_immediate(
   .clk (clk),
   .arst_n (arst_n),
   .din (immediate_extended),
   .en(enable),
   .dout(EX_immediate_extended)
);

// REG IDEX_func75 outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)IDEX_func75(
   .clk (clk),
   .arst_n (arst_n),
   .din (ID_instruction[30]),
   .en(enable),
   .dout(EX_func75)
);

// REG IDEX_func70 outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)IDEX_func70(
   .clk (clk),
   .arst_n (arst_n),
   .din (ID_instruction[25]),
   .en(enable),
   .dout(EX_func70)
);

// REG IDEX_func3 outputs
reg_arstn_en#(
   .DATA_W(3) // width of the forwarded signal
)IDEX_func3(
   .clk (clk),
   .arst_n (arst_n),
   .din (ID_instruction[14:12]),
   .en(enable),
   .dout(EX_func3)
);

// REG IDEX_waddr outputs
reg_arstn_en#(
   .DATA_W(5) // width of the forwarded signal
)IDEX_waddr(
   .clk (clk),
   .arst_n (arst_n),
   .din (ID_instruction[11:7]),
   .en(enable),
   .dout(EX_waddr)
);


// .raddr_1  (ID_instruction[19:15]),
//    .raddr_2  (ID_instruction[24:20]),
//    .waddr    (WB_waddr),

//Reg RS1 
reg_arstn_en#(
   .DATA_W(5) // width of the forwarded signal
)forward_muxA(
   .clk (clk),
   .arst_n (arst_n),
   .din (ID_instruction[19:15]),
   .en(enable),
   .dout(EX_register_rs1)
);

//Reg RS2
reg_arstn_en#(
   .DATA_W(5) // width of the forwarded signal
)forward_muxB(
   .clk (clk),
   .arst_n (arst_n),
   .din (ID_instruction[24:20]),
   .en(enable),
   .dout(EX_register_rs2)
);




// ID_EX_REG End









// EX STAGE BEGIN
branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (EX_pc),
   .immediate_extended (EX_immediate_extended),
   .branch_pc          (branch_pc),
   .jump_pc            (jump_pc)
);


mux_3 #(
   .DATA_W(64)
)ALU_forward_mux_operand0(
   .input_a(EX_regfile_rdata_1),
   .input_b(WB_regfile_wdata),//from WB stage
   .input_c(MEM_alu_out),//from MEM stage
   .select_a(ForwardA),
   .mux_out(alu_mux_forwarding_out_0)
);


mux_3 #(
   .DATA_W(64)
)ALU_forward_mux_operand1(
   .input_a(EX_regfile_rdata_2),
   .input_b(WB_regfile_wdata),//from WB stage
   .input_c(MEM_alu_out),//from MEM stage 
   .select_a(ForwardB),
   .mux_out(alu_mux_forwarding_out_1)
);


mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (EX_immediate_extended),
   .input_b (alu_mux_forwarding_out_1),
   .select_a(EX_alu_src),
   .mux_out (alu_operand_2)
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (alu_mux_forwarding_out_0),
   .alu_in_1 (alu_operand_2),
   .alu_ctrl (alu_control),
   .alu_out  (alu_out),
   .zero_flag(zero_flag),
   .overflow ()
);

alu_control alu_ctrl(
   .func7_5       (EX_func75),
   .func7_0       (EX_func70),
   .func3          (EX_func3),
   .alu_op         (EX_alu_op),
   .alu_control    (alu_control)
);

forward_unit forwarding_unit(
      .IDEX_Rs1(EX_register_rs1),//rs1
      .IDEX_Rs2(EX_register_rs2),//rs2
      .EXMEM_Rd(MEM_waddr),//rd
      .MEMWB_Rd(WB_waddr),//rd
      .EXMEM_WB(MEM_reg_write),//control signal
      .MEMWB_WB(WB_reg_write),//control signal
      .FowardA(ForwardA),
      .FowardB(ForwardB)
   );



//EX STAGE END









//EX_MEM REG BEGIN
//branch PC and jump pc register 
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)EXMEM_branchPC(
   .clk (clk),
   .arst_n (arst_n),
   .din (branch_pc), 
   .en(enable),
   .dout(MEM_branch_pc)
);
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)EXMEM_jumpPC(
   .clk (clk),
   .arst_n (arst_n),
   .din (jump_pc), 
   .en(enable),
   .dout(MEM_jump_pc)
);



// REG EXMEM_regdst outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)EXMEM_regdst(
   .clk (clk),
   .arst_n (arst_n),
   .din (EX_reg_dst), 
   .en(enable),
   .dout(MEM_reg_dst)
);

// REG EXMEM_branch outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)EXMEM_branch(
   .clk (clk),
   .arst_n (arst_n),
   .din (EX_branch), 
   .en(enable),
   .dout(MEM_branch)
);

// REG EXMEM_memread outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)EXMEM_memread(
   .clk (clk),
   .arst_n (arst_n),
   .din (EX_mem_read), 
   .en(enable),
   .dout(MEM_mem_read)
);

// REG EXMEM_mem2reg outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)EXMEM_mem2reg(
   .clk (clk),
   .arst_n (arst_n),
   .din (EX_mem_2_reg), 
   .en(enable),
   .dout(MEM_mem_2_reg)
);

// REG EXMEM_memwrite outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)EXMEM_memwrite(
   .clk (clk),
   .arst_n (arst_n),
   .din (EX_mem_write), 
   .en(enable),
   .dout(MEM_mem_write)
);

// REG EXMEM_regwrite outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)EXMEM_regwrite(
   .clk (clk),
   .arst_n (arst_n),
   .din (EX_reg_write), 
   .en(enable),
   .dout(MEM_reg_write)
);

// REG EXMEM_jump outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)EXMEM_jump(
   .clk (clk),
   .arst_n (arst_n),
   .din (EX_jump), 
   .en(enable),
   .dout(MEM_jump)
);

// REG EXMEM_PC outputs
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)EXMEM_PC(
   .clk (clk),
   .arst_n (arst_n),
   .din (EX_pc), 
   .en(enable),
   .dout(MEM_pc)
);

// REG EXMEM_zero outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)EXMEM_zero(
   .clk (clk),
   .arst_n (arst_n),
   .din (zero_flag), 
   .en(enable),
   .dout(MEM_zero_flag)
);

// REG EXMEM_aluout outputs
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)EXMEM_aluout(
   .clk (clk),
   .arst_n (arst_n),
   .din (alu_out), 
   .en(enable),
   .dout(MEM_alu_out)
);

// REG EXMEM_readdata2 outputs
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)EXMEM_readdata2(
   .clk (clk),
   .arst_n (arst_n),
   .din (EX_regfile_rdata_2), 
   .en(enable),
   .dout(MEM_regfile_rdata_2)
);

// REG EXMEM_waddr outputs
reg_arstn_en#(
   .DATA_W(5) // width of the forwarded signal
)EXMEM_waddr(
   .clk (clk),
   .arst_n (arst_n),
   .din (EX_waddr), 
   .en(enable),
   .dout(MEM_waddr)
);
//EX_MEM REG END









// MEM STAGE BEGIN
sram_BW64 #(
   .ADDR_W(10)
) data_memory(
   .clk      (clk),
   .addr     (MEM_alu_out),
   .wen      (MEM_mem_write),
   .ren      (MEM_mem_read),
   .wdata    (MEM_regfile_rdata_2),
   .rdata    (MEM_mem_data       ),   
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);
// MEM STAGE END









// MEM_WB REG BEGIN
// REG MEMWB_regdst outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)MEMWB_regdst(
   .clk (clk),
   .arst_n (arst_n),
   .din (MEM_reg_dst),
   .en(enable),
   .dout(WB_reg_dst)
);

// REG MEMWB_mem2reg outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)MEMWB_mem2reg(
   .clk (clk),
   .arst_n (arst_n),
   .din (MEM_mem_2_reg),
   .en(enable),
   .dout(WB_mem_2_reg)
);

// REG MEMWB_regwrite outputs
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)MEMWB_regwrite(
   .clk (clk),
   .arst_n (arst_n),
   .din (MEM_reg_write),
   .en(enable),
   .dout(WB_reg_write)
);

// REG MEMWB_mem_data outputs
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)MEMWB_mem_data(
   .clk (clk),
   .arst_n (arst_n),
   .din (MEM_mem_data),
   .en(enable),
   .dout(WB_mem_data)
);

// REG MEMWB_aluout outputs
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)MEMWB_aluout(
   .clk (clk),
   .arst_n (arst_n),
   .din (MEM_alu_out),
   .en(enable),
   .dout(WB_alu_out)
);

// REG MEMWB_waddr outputs
reg_arstn_en#(
   .DATA_W(5) // width of the forwarded signal
)MEMWB_waddr(
   .clk (clk),
   .arst_n (arst_n),
   .din (MEM_waddr),
   .en(enable),
   .dout(WB_waddr)
);
// MEM_WB REG END









// WB STAGE BEGIN
mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (WB_mem_data),
   .input_b  (WB_alu_out),
   .select_a (WB_mem_2_reg),
   .mux_out  (WB_regfile_wdata)
);
// WB STAGE END

endmodule