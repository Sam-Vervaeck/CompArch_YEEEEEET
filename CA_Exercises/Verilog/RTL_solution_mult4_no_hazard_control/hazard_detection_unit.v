module hazard_detection_unit
   (
      input  wire         IDEX_MemRead,
      input  wire [5-1:0] IDEX_Rd,
      input  wire [5-1:0] IFID_Rs1,
      input  wire [5-1:0] IFID_Rs2,
      input  wire         global_enable,
      output reg          NopOut,
      output reg          IFID_write,
      output reg          PC_write
   );

//This function allows you stall the pipeline when you make use of a load use case.
//

reg [2-1:0] temp_NopOut;
reg [2-1:0] temp_IFID_write;
reg [2-1:0] temp_PC_write;

always @(*) begin
    if( (IDEX_MemRead) && ( (IDEX_Rd == IFID_Rs1) || (IDEX_Rd == IFID_Rs2)  ) ) begin
        //condition for a load use case
        temp_NopOut = 1'd1;
        temp_IFID_write = 1'd0;
        temp_PC_write = 1'd0;
    end
    else begin
        if(global_enable) begin
            temp_NopOut = 1'd0;
            temp_IFID_write =1'd1;
            temp_PC_write = 1'd1;
        end
        else begin
            temp_NopOut = 1'd0;
            temp_IFID_write =1'd0;
            temp_PC_write = 1'd0;
        end
        
    end

end

assign NopOut = temp_NopOut;
assign IFID_write = temp_IFID_write;
assign PC_write = temp_PC_write;

endmodule
