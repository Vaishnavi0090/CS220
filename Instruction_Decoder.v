module Instruction_Decoder(
    input [31:0] instr,
    input [31:0] next_pc,
    output reg [5:0] op,
    output reg [4:0] src1, src2, dest, shift_amt,
    output reg [5:0] func,
    output reg [15:0] immediate,
    output reg [25:0] jump_target,
    output reg write_reg,
    output reg read_mem,
    output reg write_mem,
    output reg branch_en,
    output reg jump_en,
    output reg use_imm,
    output reg [3:0] alu_ctrl,
    output reg mem_to_reg_en,
    output reg float_op,
    output reg reg_dest_sel,
    output reg [1:0] jump_src_sel,
    output reg fp_to_int,
    output reg int_to_fp
);

always @(*) begin
    // Initialize all control signals to default values
    write_reg = 0;
    read_mem = 0;
    write_mem = 0;
    branch_en = 0;
    jump_en = 0;
    use_imm = 0;
    alu_ctrl = 4'b0000;
    mem_to_reg_en = 0;
    float_op = 0;
    reg_dest_sel = 0;
    jump_src_sel = 2'b00;
    fp_to_int = 0;
    int_to_fp = 0;

   
    op = instr[31:26];
    src1 = instr[25:21];
    src2 = instr[20:16];
    dest = instr[15:11];
    shift_amt = instr[10:6];
    func = instr[5:0];
    immediate = instr[15:0];
    jump_target = instr[25:0];

    // Instruction decoding logic
    case(op)
        // R-Type Instructions
        6'b000000: begin
            case(func)
                6'b100000: begin // ADD
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b0001;
                end
                6'b100010: begin // SUB
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b0010;
                end
                6'b100001: begin // ADDU
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b0001;
                end
                6'b100011: begin // SUBU
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b0010;
                end
                6'b111100: begin // MADD
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b0011;
                end
                6'b111101: begin // MADDU
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b0100;
                end
                6'b011000: begin // MUL
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b0101;
                end
                6'b100100: begin // AND
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b0110;
                end
                6'b100101: begin // OR
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b0111;
                end
                6'b100111: begin // NOR
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b1000;
                end
                6'b100110: begin // XOR
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b1001;
                end
                6'b101010: begin // SLT
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b1010;
                end
                6'b101011: begin // SLTU
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b1011;
                end
                6'b000000: begin // SLL
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b1110;
                end
                6'b000010: begin // SRL
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b1111;
                end
                6'b000011: begin // SRA
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b1111;
                end
                6'b000100: begin // SLA
                    write_reg = 1;
                    reg_dest_sel = 1;
                    alu_ctrl = 4'b1110;
                end
                6'b001000: begin // JR
                    jump_en = 1;
                    jump_src_sel = 2'b10;
                end
            endcase
        end

        // I-Type Instructions
        6'b001000: begin // ADDI
            write_reg = 1;
            use_imm = 1;
            alu_ctrl = 4'b0001;
        end
        6'b001001: begin // ADDIU
            write_reg = 1;
            use_imm = 1;
            alu_ctrl = 4'b0001;
        end
        6'b001100: begin // ANDI
            write_reg = 1;
            use_imm = 1;
            alu_ctrl = 4'b0110;
        end
        6'b001101: begin // ORI
            write_reg = 1;
            use_imm = 1;
            alu_ctrl = 4'b0111;
        end
        6'b001110: begin // XORI
            write_reg = 1;
            use_imm = 1;
            alu_ctrl = 4'b1001;
        end
        6'b100000: begin // LW
            write_reg = 1;
            use_imm = 1;
            read_mem = 1;
            mem_to_reg_en = 1;
            alu_ctrl = 4'b0001;
        end
        6'b101000: begin // SW
            use_imm = 1;
            write_mem = 1;
            alu_ctrl = 4'b0001;
        end
        6'b001111: begin // LUI
            write_reg = 1;
            use_imm = 1;
            alu_ctrl = 4'b1100;
        end

        // Branch Instructions
        6'b000100: begin // BEQ
            branch_en = 1;
        end
        6'b000101: begin // BNE
            branch_en = 1;
        end
        6'b000110: begin // BGT
            branch_en = 1;
        end
        6'b000111: begin // BGTE
            branch_en = 1;
        end
        6'b001000: begin // BLE
            branch_en = 1;
        end
        6'b001001: begin // BLEQ
            branch_en = 1;
        end
        6'b001010: begin // BLEU
            branch_en = 1;
        end
        6'b001011: begin // BGTU
            branch_en = 1;
        end

        // J-Type Instructions
        6'b000010: begin // J
            jump_en = 1;
        end
        6'b000011: begin // JAL
            jump_en = 1;
            write_reg = 1;
        end

        // Floating Point Instructions
        6'b110000: begin // ADD.S
            float_op = 1;
            write_reg = 1;
            alu_ctrl = 4'b0001;
        end
        6'b110001: begin // SUB.S
            float_op = 1;
            write_reg = 1;
            alu_ctrl = 4'b0010;
        end
        6'b110010: begin // C.EQ.S
            float_op = 1;
            alu_ctrl = 4'b0011;
        end
        6'b110011: begin // C.LT.S
            float_op = 1;
            alu_ctrl = 4'b0100;
        end
        6'b110100: begin // C.LE.S
            float_op = 1;
            alu_ctrl = 4'b0101;
        end
        6'b110101: begin // MOV.S
            float_op = 1;
            write_reg = 1;
            alu_ctrl = 4'b0110;
        end
        6'b110110: begin // MFC1
            float_op = 1;
            write_reg = 1;
            fp_to_int = 1;
        end
        6'b110111: begin // MTC1
            float_op = 1;
            int_to_fp = 1;
        end
    endcase
end

endmodule