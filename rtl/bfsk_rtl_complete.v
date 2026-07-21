// =====================================================================
//  PROJECT   : Simulation of a Basic Binary Frequency Shift Keying
//              (BFSK) Modulator Using Verilog
//  FILE      : bfsk_rtl_complete.v
//  AUTHOR    : [Son,Trung,Dung,Cuong,Thai]
//  COURSE    : [COS201]
//
//  DESCRIPTION:
//    Complete synthesizable RTL source for a Binary Frequency Shift
//    Keying (BFSK) modulator. Contains all sub-modules plus the
//    top-level integration module in a single file for submission.
//
//    System Clock : 50 MHz
//    Space freq f0: 500 kHz  (divisor N0 = 50)  -> data bit '0'
//    Mark  freq f1: 1 MHz    (divisor N1 = 25)  -> data bit '1'
//
//  MODULE HIERARCHY:
//    bfsk_top
//      data_input_module      (parallel-to-serial converter)
//      bfsk_modulator         (BFSK modulation core)
//
//  A separate structural decomposition of bfsk_modulator into
//  freq_control_unit + counter_divider_unit + output_toggle_reg
//  is also included at the end of this file for reference/report
//  purposes (block-diagram-to-RTL mapping). Only ONE version of
//  "bfsk_modulator" may be compiled at a time see notes below.
//
//  TOOLCHAIN : Icarus Verilog (iverilog) + GTKWave
//  STANDARD  : IEEE 1364-2001 (Verilog-2001), fully synthesizable
// =====================================================================


// =====================================================================
//  MODULE 1 : data_input_module
//  Parallel-to-Serial converter. Loads an 8-bit byte and serializes
//  it MSB-first onto serial_out at a configurable bit rate.
// =====================================================================
module data_input_module (
    input  wire        clk,           // System clock
    input  wire        rst,           // Synchronous active-high reset
    input  wire [7:0]  parallel_data, // 8-bit byte to transmit
    input  wire        load,          // Active-high 1-cycle load/start pulse
    input  wire [15:0] bit_period,    // Clock cycles per bit
    output reg         serial_out,    // MSB-first serial data stream
    output reg         tx_busy,       // High while transmitting
    output reg         tx_done        // 1-cycle pulse when all 8 bits sent
);

    localparam IDLE     = 1'b0;
    localparam TRANSMIT = 1'b1;

    reg        state;
    reg [7:0]  shift_reg;   // Holds the byte currently being shifted out
    reg [15:0] bit_timer;   // Counts clk cycles within one bit period
    reg [3:0]  bit_index;   // Tracks which bit (0-7) is being sent

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            shift_reg  <= 8'd0;
            bit_timer  <= 16'd0;
            bit_index  <= 4'd0;
            serial_out <= 1'b0;
            tx_busy    <= 1'b0;
            tx_done    <= 1'b0;
        end else begin
            tx_done <= 1'b0;   // Default: clear single-cycle pulse

            case (state)

                IDLE: begin
                    serial_out <= 1'b0;
                    tx_busy    <= 1'b0;
                    if (load) begin
                        shift_reg  <= parallel_data;
                        serial_out <= parallel_data[7];  // Output MSB first
                        bit_timer  <= 16'd0;
                        bit_index  <= 4'd0;
                        tx_busy    <= 1'b1;
                        state      <= TRANSMIT;
                    end
                end

                TRANSMIT: begin
                    if (bit_timer >= bit_period - 1) begin
                        bit_timer <= 16'd0;
                        if (bit_index == 4'd7) begin                        
                            state      <= IDLE;
                            tx_busy    <= 1'b0;
                            tx_done    <= 1'b1;
                            serial_out <= 1'b0;
                            bit_index  <= 4'd0;
                        end else begin
                            shift_reg  <= {shift_reg[6:0], 1'b0};
                            serial_out <= shift_reg[6];
                            bit_index  <= bit_index + 4'd1;
                        end
                    end else begin
                        bit_timer <= bit_timer + 16'd1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule


// =====================================================================
//  MODULE 2 : bfsk_modulator 
//  Core BFSK modulation engine. Generates a square-wave output that
//  toggles at frequency f1 when data_in='1', or f0 when data_in='0'.
// =====================================================================
module bfsk_modulator (
    input  wire clk,            // Master system clock
    input  wire rst,            // Synchronous active-high reset
    input  wire data_in,        // Serial binary data input
    output reg  modulated_out   // BFSK modulated square-wave output
);

    parameter F0_DIV = 8'd50;   // Space frequency divisor (bit '0') -> 500 kHz
    parameter F1_DIV = 8'd25;   // Mark  frequency divisor (bit '1') -> 1 MHz

    reg [7:0] counter;          // Clock-cycle counter

    always @(posedge clk) begin
        if (rst) begin
            counter       <= 8'd0;
            modulated_out <= 1'b0;

        end else begin

            if (data_in == 1'b1) begin
              if (counter >= F1_DIV - 8'd1) begin
                    counter       <= 8'd0;
                    modulated_out <= ~modulated_out;
                end else begin
                    counter <= counter + 8'd1;
                end

            end else begin               
               if (counter >= F0_DIV - 8'd1) begin
                    counter       <= 8'd0;
                    modulated_out <= ~modulated_out;
                end else begin
                    counter <= counter + 8'd1;
                end
            end

        end
    end

endmodule


// =====================================================================
//  MODULE 3 : bfsk_top  (TOP-LEVEL INTEGRATION MODULE)
//  Connects data_input_module -> bfsk_modulator.
//  This is the module to instantiate on the FPGA / in the testbench.
// =====================================================================
module bfsk_top (
    input  wire        clk,            // Master clock (50 MHz)
    input  wire        rst,            // Synchronous active-high reset
    input  wire [7:0]  parallel_data,  // 8-bit byte to transmit
    input  wire        load,           // Pulse high to start transmission
    output wire        modulated_out,  // BFSK modulated output
    output wire        tx_busy,        // High during transmission
    output wire        tx_done         // 1-cycle pulse when byte is sent
);

    parameter F0_DIV     = 8'd50;      // Space divisor (bit '0')
    parameter F1_DIV     = 8'd25;      // Mark  divisor (bit '1')
    parameter BIT_PERIOD = 16'd2500;   // Clock cycles per bit (20 kbps @ 50 MHz)

    wire serial_data;   // Serial output from DIM -> input to modulator

    data_input_module u_dim (
        .clk           (clk),
        .rst           (rst),
        .parallel_data (parallel_data),
        .load          (load),
        .bit_period    (BIT_PERIOD),
        .serial_out    (serial_data),
        .tx_busy       (tx_busy),
        .tx_done       (tx_done)
    );

    
    bfsk_modulator #(
        .F0_DIV (F0_DIV),
        .F1_DIV (F1_DIV)
    ) u_mod (
        .clk           (clk),
        .rst           (rst),
        .data_in       (serial_data),
        .modulated_out (modulated_out)
    );

endmodule


