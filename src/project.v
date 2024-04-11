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
  // Output ---------
  wire [7:0] addr;
  wire addr_sel;
  mux2 addr_sel_ (addr_sel, pc_reg_out, reg_reg_out, addr);
  assign uo_out = addr;

  // Tristate IO ----
  wire [7:0] data_in;
  wire [7:0] data_out;
  wire write;
  assign data_in = uio_in;
  assign uio_out = data_out;
  assign uio_oe = write ? 8'b11111111 : 8'b00000000;
  
  // Registers ------
  // PC
  wire pc_en;
  wire [7:0] pc_reg_out;
  dff pc_reg (clk, pc_en, alu_out, rst_n, pc_reg_out);
  // Reg
  wire reg_en;
  wire [7:0] reg_reg_out;
  dff reg_reg (clk, reg_en, alu_out, rst_n, reg_reg_out);
  // Depth
  wire depth_en;
  wire [7:0] depth_reg_out;
  wire depth_signal;
  wire depth_is_zero;
  wire looping;
  dff depth_reg (clk, depth_en, alu_out, rst_n, depth_reg_out);
  signal depth_signal_ (depth_reg_out, depth_signal);
  is_zero depth_is_zero_ (depth_reg_out, depth_is_zero);
  assign looping = ~depth_is_zero;
  // Temp
  wire temp_en;
  wire [7:0] temp_reg_out;
  assign data_out = temp_reg_out;

  wire [7:0] data_sel_out;
  wire data_is_zero;
  wire data_sel;
  mux2 data_sel_mux (data_sel, data_in, alu_out, data_sel_out);

  dff temp_reg (clk, temp_en, data_sel_out, rst_n, temp_reg_out);
  is_zero temp_is_zero (temp_reg_out, data_is_zero);

  // ALU ------------
  wire [7:0] alu_in_b;
  assign alu_in_b = 1;

  wire [7:0] alu_in_a;
  wire [1:0] alu_sel;
  mux4 alu_sel_mux (alu_sel, pc_reg_out, reg_reg_out, depth_reg_out, temp_reg_out, alu_in_a);

  wire [7:0] alu_out;
  wire operation;
  alu alu_ (operation, alu_in_a, alu_in_b, alu_out);

  // FSM ------------
  // Instr Reg
  wire instr_en;
  wire [7:0] instr_reg_out;
  dff instr_reg (clk, instr_en, data_in, rst_n, instr_reg_out);
  // State Machine
  fsm fsm_ (
	  clk, ena, rst_n, instr_reg_out,
          looping, depth_signal, data_is_zero,
	  pc_en, reg_en, depth_en, temp_en, instr_en,
          write, operation, alu_sel, data_sel, addr_sel
  );

endmodule
