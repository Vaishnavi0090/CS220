module Processor_Top(
    input clock,
    input reset_n,
    output [31:0] alu_output,
    output [31:0] current_instruction,
    output [31:0] next_pc_value,
    output branch_active
);

    // Inter-module connection signals
    wire [31:0] reg_data1, reg_data2, jump_target_addr;
    wire [15:0] immediate_value;
    wire [31:0] sign_ext_imm = {{16{immediate_value[15]}}, immediate_value};
    wire [31:0] fp_reg_data1, fp_reg_data2, fp_result;
    wire [31:0] mem_output, wb_data;
    wire [4:0] src_reg1, src_reg2, dest_reg, shift_amount;
    wire [5:0] opcode_field, function_field;
    
    // Control signals
    wire reg_write_en, mem_read_en, mem_write_en;
    wire branch_en, jump_en, alu_src_sel;
    wire [3:0] alu_control, fpu_control;
    wire float_operation, mem_to_reg_sel;
    wire fp_condition_code;
    wire gpr_to_fpr_en, fpr_to_gpr_en;

    // Instruction Fetch Stage
    Instruction_Fetch_Unit IFU (
        .clock(clock),
        .reset_n(reset_n),
        .jump_address(jump_target_addr),
        .branch_condition(branch_active || jump_en),
        .current_instruction(current_instruction),
        .next_instruction_addr(next_pc_value)
    );

    // Instruction Decode Stage
    Instruction_Decoder ID (
        .instr(current_instruction),
        .next_pc(next_pc_value),
        .op(opcode_field),
        .src1(src_reg1),
        .src2(src_reg2),
        .dest(dest_reg),
        .shift_amt(shift_amount),
        .func(function_field),
        .immediate(immediate_value),
        .write_reg(reg_write_en),
        .read_mem(mem_read_en),
        .write_mem(mem_write_en),
        .branch_en(branch_en),
        .jump_en(jump_en),
        .use_imm(alu_src_sel),
        .alu_ctrl(alu_control),
        .mem_to_reg_en(mem_to_reg_sel),
        .float_op(float_operation),
        .fp_to_int(fpr_to_gpr_en),
        .int_to_fp(gpr_to_fpr_en)
    );

    // Register File Unit
    Register_File_Unit RFU (
        .clock(clock),
        .reset_signal(reset_n),
        
        // Integer register interface
        .int_read_addr1(src_reg1),
        .int_read_addr2(src_reg2),
        .int_read_data1(reg_data1),
        .int_read_data2(reg_data2),
        .int_write_addr(dest_reg),
        .int_write_data(wb_data),
        .int_write_enable(reg_write_en && !float_operation),
        
        // Floating-point interface
        .fp_read_addr1(src_reg1),
        .fp_read_addr2(src_reg2),
        .fp_read_data1(fp_reg_data1),
        .fp_read_data2(fp_reg_data2),
        .fp_write_addr(dest_reg),
        .fp_write_data(fp_result),
        .fp_write_enable(reg_write_en && float_operation),
        
        // Move operations
        .gpr_to_fpr_en(gpr_to_fpr_en),
        .fpr_to_gpr_en(fpr_to_gpr_en),
        .move_reg_num(dest_reg)
    );

    // Arithmetic Logic Unit
    ALU_Unit main_alu (
        .operand_A(reg_data1),
        .operand_B(alu_src_sel ? sign_ext_imm : reg_data2),
        .operation_code(alu_control),
        .is_float(float_operation),
        .result(alu_output),
        .fp_cc(fp_condition_code)
    );

    // Floating Point Unit
    FPU floating_point_unit (
        .src1(fp_reg_data1),
        .src2(fp_reg_data2),
        .fpu_control(alu_control),
        .fpu_result(fp_result),
        .status_flag(fp_condition_code)
    );

    // Data Memory Unit
    Memory_Unit data_mem (
        .clock(clock),
        .reset_signal(reset_n),
        .read_enable(mem_read_en),
        .write_enable(mem_write_en),
        .mem_address(alu_output),
        .data_in(reg_data2),
        .data_out(mem_output)
    );

    // Branch Control Unit
    Branch_Control branch_ctl (
        .reg_src1_val(reg_data1),
        .reg_src2_val(reg_data2),
        .immediate_val(immediate_value),
        .operation(opcode_field),
        .branch_decision(branch_active),
        .jump_address(jump_target_addr)
    );

    // Write-back MUX
    assign wb_data = (float_operation && !fpr_to_gpr_en && !gpr_to_fpr_en) ? 
                    fp_result : 
                    (mem_to_reg_sel ? mem_output : alu_output);

endmodule