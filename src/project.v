/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_loco_choco (
    input  wire [7:0] ui_in,    // Dedicated inputs -> Nothing
    output wire [7:0] uo_out,   // Dedicated outputs -> (0-> Write, 1-> Addr)
    input  wire [7:0] uio_in,   // IOs: Input path -> Data (Read Mode)
    output wire [7:0] uio_out,  // IOs: Output path -> Data (Write Mode)
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output) -> Pseudo Write Pin
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  // Output ---------
  wire instr_addr;
  wire addr;
  wire write;
  wire [12:8] pc_extension;
  assign uo_out[0] = write;
  assign uo_out[1] = addr;
  assign uo_out[2] = instr_addr;
  assign uo_out[7:3] = pc_extension;

  // Tristate IO ----
  wire [7:0] data_in;
  wire [7:0] data_out;
  wire addr_sel;
  wire [7:0] addr_sel_out;
  assign instr_addr = addr & ~addr_sel; // we have addr selected and it is outputing the pc 
  assign pc_extension = pc_reg_out[12:8] & {5{instr_addr}}; // extended pc!
  mux2 addr_sel_ (addr_sel, pc_reg_out[7:0], reg_reg_out, addr_sel_out);
  mux2 out_sel (addr, temp_reg_out, addr_sel_out, data_out);
  assign data_in = uio_in;
  assign uio_out = data_out;
  assign uio_oe = {8{write}};
  
  // Registers ------
  // PC
  wire pc_en;
  wire [12:0] pc_reg_out;
  dff14 pc_reg (clk, pc_en, alu_out, rst_n, pc_reg_out);
  // Reg
  wire reg_en;
  wire [7:0] reg_reg_out;
  dff reg_reg (clk, reg_en, alu_out[7:0], rst_n, reg_reg_out);
  // Depth
  wire depth_en;
  wire [12:0] depth_reg_out;
  wire depth_signal;
  wire depth_is_zero;
  wire looping;
  dff14 depth_reg (clk, depth_en, alu_out, rst_n, depth_reg_out);
  signal depth_signal_ (depth_reg_out, depth_signal);
  is_zero14 depth_is_zero_ (depth_reg_out, depth_is_zero);
  assign looping = ~depth_is_zero;
  // Temp
  wire temp_en;
  wire [7:0] temp_reg_out;

  wire [7:0] data_sel_out;
  wire data_is_zero;
  wire data_sel;
  mux2 data_sel_mux (data_sel, data_in, alu_out[7:0], data_sel_out);

  dff temp_reg (clk, temp_en, data_sel_out, rst_n, temp_reg_out);
  is_zero temp_is_zero (temp_reg_out, data_is_zero);

  // ALU ------------
  wire [12:0] alu_in_b;
  assign alu_in_b = 1;

  wire [12:0] alu_in_a;
  wire [1:0] alu_sel;
  mux4 alu_sel_mux (alu_sel, pc_reg_out, {5'd0, reg_reg_out}, depth_reg_out, {5'd0,temp_reg_out}, alu_in_a);

  wire [12:0] alu_out;
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
          write, addr, operation, alu_sel, data_sel, addr_sel
  );

endmodule
