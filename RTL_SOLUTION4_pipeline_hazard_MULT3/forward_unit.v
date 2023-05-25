module forward_unit
   (
      input  wire [5-1:0] IDEX_Rs1,
      input  wire [5-1:0] IDEX_Rs2,
      input  wire [5-1:0] EXMEM_Rd,
      input  wire [5-1:0] MEMWB_Rd,
      input  wire              EXMEM_WB,
      input  wire              MEMWB_WB,
      output reg  [2-1:0] FowardA,
      output reg  [2-1:0] FowardB
   );
//Start the logic 

//outline
//Forward A = 00 First operand Comes from the register file 
//Forward A = 10 First operand is forwarded from the prior ALU result
//Forward A = 01 First operand is forwarded from the data memory or a previous ALU result

//Forward B = 00 Second operand Comes from the register file
//Forward B = 10 Second operand is forwarded from the prior ALU result
//Forward B = 01 Second operand is forwarded from the data memory or a previous ALU result

reg [2-1:0] tempA;
reg [2-1:0] tempB;

always @(*) begin

    //forward A
    if( (EXMEM_WB == 1 ) && (EXMEM_Rd != 0 ) && (EXMEM_Rd == IDEX_Rs1) ) begin
        //forwarding from the ALU
        tempA = 2'b00;
    end
    else if( (MEMWB_WB == 1 ) && ( MEMWB_Rd != 0 ) && ( ~(EXMEM_WB == 1 && (EXMEM_Rd != 0 )) ) && (EXMEM_Rd == IDEX_Rs1) && (MEMWB_Rd == IDEX_Rs1) ) 
    begin
        //forwarding from the the WB stage 
        tempA =2'b01;
    end
    else begin
        //no forwarding
        tempA = 2'b10;//2'b00; in the TB
    end

    //forward B
    if( (EXMEM_WB ==  1 ) && (EXMEM_Rd != 0 ) && (EXMEM_Rd == IDEX_Rs2) ) begin
        tempB = 2'b00;
    end
    else if( ( MEMWB_WB == 1 ) && ( MEMWB_Rd != 0 ) && ( ~( EXMEM_WB == 1 && ( EXMEM_Rd != 0 )) ) && (EXMEM_Rd == IDEX_Rs2) && (MEMWB_Rd == IDEX_Rs2) ) begin 
        tempB =2'b01;
    end
    else begin
        tempB =2'b10;
    end

end

assign FowardA = tempA;
assign FowardB = tempB;


endmodule
