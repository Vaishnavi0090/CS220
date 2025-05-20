module Register_File_Unit(
    input clock,
    input reset_signal,
    
    // Integer register interface
    input [4:0] int_read_addr1,
    input [4:0] int_read_addr2,
    output reg [31:0] int_read_data1,
    output reg [31:0] int_read_data2,
    input [4:0] int_write_addr,
    input [31:0] int_write_data,
    input int_write_enable,
    
    // Floating-point register interface
    input [4:0] fp_read_addr1,
    input [4:0] fp_read_addr2,
    output reg [31:0] fp_read_data1,
    output reg [31:0] fp_read_data2,
    input [4:0] fp_write_addr,
    input [31:0] fp_write_data,
    input fp_write_enable,
    
    // Register move operations
    input gpr_to_fpr_en,    // Move from integer to FP register
    input fpr_to_gpr_en,    // Move from FP to integer register
    input [4:0] move_reg_num  // Register number for move operations
);

    // Register storage
    reg [31:0] integer_registers [0:31];  // 32 general-purpose registers
    reg [31:0] float_registers [0:31];    // 32 floating-point registers

    // Integer register read operations
    always @(*) begin
        // First read port
        int_read_data1 = (int_read_addr1 == 0) ? 32'b0 : integer_registers[int_read_addr1];
        
        // Second read port
        int_read_data2 = (int_read_addr2 == 0) ? 32'b0 : integer_registers[int_read_addr2];
    end

    // Floating-point register read operations
    always @(*) begin
        fp_read_data1 = float_registers[fp_read_addr1];
        fp_read_data2 = float_registers[fp_read_addr2];
    end

    // Integer register write operations
    always @(posedge clock or posedge reset_signal) begin
        if (reset_signal) begin
            // Initialize all registers on reset
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                integer_registers[i] <= 32'b0;
            end
            // Set special register values
            integer_registers[29] <= 32'h80000000;  // Stack pointer
            integer_registers[28] <= 32'h10008000;  // Global pointer
            integer_registers[30] <= 32'h00000000;  // Frame pointer
        end
        else begin
            // Normal register write
            if (int_write_enable && int_write_addr != 0) begin
                integer_registers[int_write_addr] <= int_write_data;
            end
            
            // Move from FP to integer register
            if (fpr_to_gpr_en && move_reg_num != 0) begin
                integer_registers[move_reg_num] <= float_registers[fp_read_addr1];
            end
        end
    end

    // Floating-point register write operations
    always @(posedge clock or posedge reset_signal) begin
        if (reset_signal) begin
            // Initialize all FP registers on reset
            integer j;
            for (j = 0; j < 32; j = j + 1) begin
                float_registers[j] <= 32'b0;
            end
        end
        else begin
            // Normal FP register write
            if (fp_write_enable) begin
                float_registers[fp_write_addr] <= fp_write_data;
            end
            
            // Move from integer to FP register
            if (gpr_to_fpr_en) begin
                float_registers[move_reg_num] <= integer_registers[int_read_addr1];
            end
        end
    end

endmodule