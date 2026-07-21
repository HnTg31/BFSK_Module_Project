// =============================================================
// Module   : bfsk_golden_model.v
// Function : GOLDEN REFERENCE MODEL for the BFSK Modulator
//
//            Behavioral, algorithmically independent
//            re-implementation of the BFSK modulator core, used
//            ONLY for verification — to check that bfsk_modulator
//            (inside bfsk_rtl_complete.v) produces bit-exact
//            correct output.
//
//            Deliberately coded in a different style than the DUT
//            so that a bug common to both models is unlikely to
//            go undetected. NOT synthesizable — simulation only.
//
// Behavior (must match bfsk_modulator bit-for-bit):
//   data_in = '1'  ->  toggle every F1_DIV clock cycles
//   data_in = '0'  ->  toggle every F0_DIV clock cycles
//   rst = '1'      ->  counter=0, out=0 (synchronous)
// =============================================================

module bfsk_golden_model (
    input  wire clk,
    input  wire rst,
    input  wire data_in,
    output reg  gold_out    // Golden/expected output
);

    parameter F0_DIV = 8'd50;
    parameter F1_DIV = 8'd25;

    integer half_period_count;
    integer active_divisor;

    always @(posedge clk) begin
        if (rst) begin
            half_period_count <= 0;
            gold_out          <= 1'b0;
        end else begin
            active_divisor = (data_in) ? F1_DIV : F0_DIV;

            if (half_period_count >= active_divisor - 1) begin
                half_period_count <= 0;
                gold_out          <= !gold_out;
            end else begin
                half_period_count <= half_period_count + 1;
            end
        end
    end

endmodule
