/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_loco_choco (
    input  wire [7:0] ui_in,    // Dedicated inputs -> Nothing
    output wire [7:0] uo_out,   // Dedicated outputs -> Addr
    input  wire [7:0] uio_in,   // IOs: Input path -> Data (Read Mode)
    output wire [7:0] uio_out,  // IOs: Output path -> Data (Write Mode)
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output) -> Pseudo Write Pin
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  // Output
  wire addr;
  assign addr = uo_out;
  // Tristate IO
  // Turn uio into tristate module

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

endmodule
