module Branch_Control(
    input [31:0] reg_src1_val,
    input [31:0] reg_src2_val,
    input [31:0] immediate_val,
    input [5:0] operation,
    output reg branch_decision,
    output [31:0] jump_address
);

    // Sign-extend and shift immediate value for target calculation
    assign jump_address = {{14{immediate_val[15]}}, immediate_val, 2'b00};

    // Signed/unsigned value conversions
    wire signed [31:0] signed_val1 = reg_src1_val;
    wire signed [31:0] signed_val2 = reg_src2_val;
    wire [31:0] unsigned_val1 = reg_src1_val;
    wire [31:0] unsigned_val2 = reg_src2_val;

   
    always @(*) begin
        case(operation)
            
            6'b000100: branch_decision = (reg_src1_val == reg_src2_val);  // Branch if equal
            6'b000101: branch_decision = (reg_src1_val != reg_src2_val);  // Branch if not equal
            
            // Signed comparisons
            6'b000110: branch_decision = (signed_val1 > signed_val2);    // Branch if greater than (signed)
            6'b000111: branch_decision = (signed_val1 >= signed_val2);   // Branch if greater/equal (signed)
            6'b001000: branch_decision = (signed_val1 < signed_val2);    // Branch if less than (signed)
            6'b001001: branch_decision = (signed_val1 <= signed_val2);   // Branch if less/equal (signed)
            
            // Unsigned comparisons
            6'b001010: branch_decision = (unsigned_val1 < unsigned_val2); // Branch if less than (unsigned)
            6'b001011: branch_decision = (unsigned_val1 > unsigned_val2); // Branch if greater than (unsigned)
            
            
            default: branch_decision = 1'b0;
        endcase
    end

endmodule