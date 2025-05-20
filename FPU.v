module FPU (
    input [31:0] src1,
    input [31:0] src2,
    input [3:0] fpu_control,
    output reg [31:0] fpu_result,
    output reg status_flag,
    output reg exception,
    output reg overflow_flag,
    output reg underflow_flag
);

    // Floating-point comparison results
    reg equal_flag, less_flag, less_equal_flag, greater_flag, greater_equal_flag;
    
    // Operation results storage
    reg [31:0] add_out, sub_out;
    
    // Constants for special exponent values
    localparam MIN_EXP = 8'b00000000;
    localparam MAX_EXP = 8'b11111111;

    // Input decomposition and normalization
    wire op1_sign = src1[31];
    wire op2_sign = src2[31];
    wire [7:0] op1_exp = src1[30:23];
    wire [7:0] op2_exp = src2[30:23];
    wire [23:0] op1_mant = (op1_exp == 0) ? {1'b0, src1[22:0]} : {1'b1, src1[22:0]};
    wire [23:0] op2_mant = (op2_exp == 0) ? {1'b0, src2[22:0]} : {1'b1, src2[22:0]};

    // Comparison logic moved to the top
    always @(*) begin
        equal_flag = (src1 == src2);
        less_flag = ($signed({op1_sign, op1_exp, op1_mant}) < 
                   $signed({op2_sign, op2_exp, op2_mant}));
        less_equal_flag = less_flag | equal_flag;
        greater_flag = !less_equal_flag;
        greater_equal_flag = !less_flag;
    end

    // Normalization function placed near operations that use it
    function [31:0] pack_float_result;
        input sign;
        input [7:0] exponent;
        input [24:0] mantissa;
        begin
            if (exponent == 0 || exponent >= MAX_EXP) begin
                pack_float_result = {sign, MAX_EXP, 23'b0};
            end else begin
                pack_float_result = {sign, exponent, mantissa[22:0]};
            end
        end
    endfunction

    // Arithmetic operations
    always @(*) begin
        // Variables for alignment and computation
        reg [24:0] aligned_larger, aligned_smaller;
        reg [7:0] final_exp;
        reg result_sign_bit;
        reg [24:0] computed_mantissa;
        
        // Determine which operand has larger exponent
        if (op1_exp > op2_exp) begin
            aligned_larger = {1'b0, op1_mant};
            aligned_smaller = {1'b0, op2_mant} >> (op1_exp - op2_exp);
            final_exp = op1_exp;
        end else begin
            aligned_larger = {1'b0, op2_mant};
            aligned_smaller = {1'b0, op1_mant} >> (op2_exp - op1_exp);
            final_exp = op2_exp;
        end

        // Addition operation
        if (fpu_control == 4'b0001) begin
            if (op1_sign == op2_sign) begin
                computed_mantissa = aligned_larger + aligned_smaller;
                result_sign_bit = op1_sign;
            end else begin
                if (aligned_larger > aligned_smaller) begin
                    computed_mantissa = aligned_larger - aligned_smaller;
                    result_sign_bit = op1_sign;
                end else begin
                    computed_mantissa = aligned_smaller - aligned_larger;
                    result_sign_bit = op2_sign;
                end
            end
            
            // Normalization step
            if (computed_mantissa[24]) begin
                computed_mantissa = computed_mantissa >> 1;
                final_exp = final_exp + 1;
            end
            add_out = pack_float_result(result_sign_bit, final_exp, computed_mantissa);
        end

        // Subtraction operation
        if (fpu_control == 4'b0010) begin
            if (op1_sign != op2_sign) begin
                computed_mantissa = aligned_larger + aligned_smaller;
                result_sign_bit = op1_sign;
            end else begin
                if (aligned_larger > aligned_smaller) begin
                    computed_mantissa = aligned_larger - aligned_smaller;
                    result_sign_bit = op1_sign;
                end else begin
                    computed_mantissa = aligned_smaller - aligned_larger;
                    result_sign_bit = ~op1_sign;
                end
            end
            
            // Normalization step
            if (computed_mantissa[24]) begin
                computed_mantissa = computed_mantissa >> 1;
                final_exp = final_exp + 1;
            end
            sub_out = pack_float_result(result_sign_bit, final_exp, computed_mantissa);
        end
    end

    // Output generation logic
    always @(*) begin
        // Default outputs
        fpu_result = 32'b0;
        status_flag = 1'b0;
        exception = 1'b0;
        overflow_flag = 1'b0;
        underflow_flag = 1'b0;

        // Operation selection
        case (fpu_control)
            4'b0000: fpu_result = src1;                  // Move operation
            4'b0001: fpu_result = add_out;               // Floating add
            4'b0010: fpu_result = sub_out;               // Floating subtract
            4'b0011: status_flag = equal_flag;           // Equality test
            4'b0100: status_flag = less_flag;            // Less than test
            4'b0101: status_flag = less_equal_flag;      // Less or equal test
            4'b0110: status_flag = greater_equal_flag;   // Greater or equal
            4'b0111: status_flag = greater_flag;         // Greater than test
            4'b1000: fpu_result = src2;                  // Register move
            default: exception = 1'b1;                   // Invalid operation
        endcase
    end

endmodule