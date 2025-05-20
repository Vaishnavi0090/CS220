module ArithmeticLogicUnit (
    input wire [31:0] operand_A,
    input wire [31:0] operand_B,
    input wire [3:0] operation_code,
    input wire floating_point_en,
    output reg [31:0] alu_out,
    output reg equal_zero,
    output fp_status,
    output of_flag,
    output cy_flag
);

    // Internal signals for integer and floating-point operations
    wire [31:0] integer_output, floating_output;
    wire fp_equal_zero, fp_exception, fp_of, fp_uf;
    wire fpu_status;

    // Floating Point Unit instantiation
    FPU fpu_unit (
        .src1(operand_A),
        .src2(operand_B),
        .fpu_control(operation_code),
        .fpu_result(floating_output),
        .status_flag(fpu_status),
        .exception(fp_exception),
        .overflow_flag(fp_of),
        .underflow_flag(fp_uf)
    );

    // Integer operations processing
    always @(*) begin
        equal_zero = 1'b0;
        case(operation_code)
            4'b0001: alu_out = operand_A + operand_B;       // Addition
            4'b0010: alu_out = operand_A - operand_B;       // Subtraction
            4'b0011: alu_out = $signed(operand_A) * $signed(operand_B); // Signed multiply-add
            4'b0100: alu_out = operand_A * operand_B;       // Unsigned multiply-add
            4'b0101: alu_out = operand_A * operand_B;       // Multiplication
            4'b0110: alu_out = operand_A & operand_B;       // Bitwise AND
            4'b0111: alu_out = operand_A | operand_B;       // Bitwise OR
            4'b1000: alu_out = ~(operand_A | operand_B);     // Bitwise NOR
            4'b1001: alu_out = operand_A ^ operand_B;        // Bitwise XOR
            4'b1010: alu_out = ($signed(operand_A) < $signed(operand_B)) ? 32'd1 : 32'd0; // Signed comparison
            4'b1011: alu_out = (operand_A < operand_B) ? 32'd1 : 32'd0; // Unsigned comparison
            4'b1100: alu_out = {operand_B[15:0], 16'b0};    // Load upper immediate
            4'b1110: alu_out = operand_B << operand_A[4:0]; // Shift left
            4'b1111: alu_out = operand_B >> operand_A[4:0]; // Shift right
            default: alu_out = 32'b0;
        endcase
        
        // Zero flag determination
        if (floating_point_en) begin
            equal_zero = (floating_output == 32'b0);
        end else begin
            equal_zero = (alu_out == 32'b0);
        end
    end

    // Output selection and flag assignments
    assign alu_out = floating_point_en ? floating_output : integer_output;
    assign fp_status = fpu_status;
    assign of_flag = floating_point_en ? fp_of : (operation_code[3:0] == 4'b0001) && (alu_out[31] != operand_A[31]);
    assign cy_flag = !floating_point_en && (operation_code[3:0] == 4'b0001) && (alu_out < operand_A);

endmodule