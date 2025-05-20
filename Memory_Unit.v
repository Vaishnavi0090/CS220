module Memory_Unit (
    input clock,
    input reset_signal,
    input read_enable,
    input write_enable,
    input [31:0] mem_address,
    input [31:0] data_in,
    output reg [31:0] data_out
);

    // Memory storage with 256 words (32-bit each)
    reg [31:0] storage_array [0:255];


    always @(posedge clock or posedge reset_signal) begin
        // Reset logic
        if (reset_signal) begin
            integer index;
            for (index = 0; index < 256; index = index + 1) begin
                storage_array[index] <= 32'h00000000;
            end
        end
        else begin
            // Write operation has priority over read
            if (write_enable) begin
                storage_array[mem_address[7:0]] <= data_in;
            end
            
            // Read operation (non-blocking for consistent behavior)
            if (read_enable) begin
                data_out <= storage_array[mem_address[7:0]];
            end
        end
    end

endmodule