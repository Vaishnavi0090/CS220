module Instruction_Fetch_Unit(
    input clock,
    input reset_n,
    input [31:0] jump_address,
    input branch_condition,
    output [31:0] current_instruction,
    output [31:0] next_instruction_addr
);

   
    reg [31:0] program_counter;
    reg [31:0] instruction_memory [0:63];  
    
    // Next PC Calculation
    wire [31:0] subsequent_pc = branch_condition ? jump_address : (program_counter + 32'd4);
    assign next_instruction_addr = program_counter + 32'd4;
    
    // PC Update Logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            program_counter <= 32'h00000000;  // Reset to start of memory
        end else begin
            program_counter <= subsequent_pc;  // Normal PC update
        end
    end
    
    // Instruction Memory Access (word-aligned)
    assign current_instruction = instruction_memory[program_counter[15:2]];

endmodule