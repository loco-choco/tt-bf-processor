/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module fsm (
    input wire clk,
    input wire en,
    input wire nreset,
    input wire [7:0] instr,

    input wire looping,
    input wire depth_signal,
    input wire data_is_zero,

    output reg pc_en,
    output reg reg_en,
    output reg depth_en,
    output reg temp_en,
    output reg instr_en,

    output reg write,
    output reg operation,
    output reg [1:0] alu_sel,
    output reg data_sel,
    output reg addr_sel
);

// Selection consts for alu_sel
localparam ALU_SEL_PC = 2'd0,
	   ALU_SEL_Reg = 2'd1,
	   ALU_SEL_Depth = 2'd2,
	   ALU_SEL_Temp = 2'd3;
// Selection consts for data_sel
localparam TEMP_DATA_SEL_Data = 1'd0,
	   TEMP_DATA_SEL_Alu = 1'd1;
// Selection consts for addr_sel
localparam ADDR_SEL_PC = 1'd0,
	   ADDR_SEL_Reg = 1'd1;

// Decode Instr Input
reg [2:0] decoded_instr;
reg not_instr;
always @ (instr) begin
  case (instr)
    "+" : begin
      not_instr = 0;
      decoded_instr = 3'b000;
    end
    "-" : begin
      not_instr = 0;
      decoded_instr = 3'b001;
    end

    ">" : begin
      not_instr = 0;
      decoded_instr = 3'b010;
    end

    "<" : begin
      not_instr = 0;
      decoded_instr = 3'b011;
    end

    "[" : begin
      not_instr = 0;
      decoded_instr = 3'b100;
    end

    "]" : begin
      not_instr = 0;
      decoded_instr = 3'b101;
    end

    default : begin
      not_instr = 1;
      decoded_instr = 3'd0;
    end
  endcase
end


// States
localparam STATE_Next_PC = 3'd1,
	   STATE_Fetch_Instr = 3'd0, // Fetch Instr is the real initial state, as the PC is zero here
	   // +/-
	   STATE_Sum_Sub_Fetch_Data = 3'd2, // Step 1 -> Fetching Data
	   STATE_Sum_Sub_Operate_Data = 3'd3, // Step 2 -> Data++/--
	   STATE_Sum_Sub_Write_Data = 3'd4, // Step 2 -> Save result in mem||y
	   // >/<
	   STATE_Shift_Reg = 3'd5, // Reg++/--
	   // [/]
	   STATE_Loop_Fetch_Data = 3'd6, // If Looping = 0, Fetch Data
	   STATE_Loop_Operate_Depth = 3'd7; // If Looping = 1 || data matches condition, Depth++/--

// State Regs
reg[2:0] current_state;
reg[2:0] next_state;

// Looping condition

wire looping_condition;
assign looping_condition = (data_is_zero && decoded_instr == 3'b100) || (~data_is_zero && decoded_instr == 3'b101);

// Outputs
always @ ( * ) begin
    // Base values
    pc_en = 0;
    reg_en = 0;
    depth_en = 0;
    temp_en = 0;
    instr_en = 0;

    write = 0;

    operation = 0;
    alu_sel = ALU_SEL_PC;
    data_sel = TEMP_DATA_SEL_Data;
    addr_sel = ADDR_SEL_PC;

  case (current_state)
    STATE_Next_PC : begin
      alu_sel = ALU_SEL_PC; // pc++/--, depends on the signal of depth
      operation = depth_signal;
      pc_en = 1; // pc = pc++/--
    end
    STATE_Fetch_Instr : begin
      addr_sel = ADDR_SEL_PC; // addr = pc
      instr_en = 1; // instr = data
    end
    // +/-
    STATE_Sum_Sub_Fetch_Data : begin
      addr_sel = ADDR_SEL_Reg; // addr = reg
      data_sel = TEMP_DATA_SEL_Data; // temp = data
      temp_en = 1;
    end
    STATE_Sum_Sub_Operate_Data : begin
      alu_sel = ALU_SEL_Temp; // temp++/--
      operation = decoded_instr[0]; // if +, ++, -, --
      data_sel = TEMP_DATA_SEL_Alu; // temp = temp++/--
      temp_en = 1;
    end
    STATE_Sum_Sub_Write_Data : begin
      addr_sel = ADDR_SEL_Reg; // addr = reg
      write = 1;
    end
    // >/<
    STATE_Shift_Reg : begin
      alu_sel = ALU_SEL_Reg; // reg++/--
      operation = decoded_instr[0]; // if >, ++, <, --
      reg_en = 1; // reg = reg++/--
    end
    // [/]
    STATE_Loop_Fetch_Data : begin
      addr_sel = ADDR_SEL_Reg; // addr = reg
      data_sel = TEMP_DATA_SEL_Data; // temp = data
      temp_en = 1;
    end
    STATE_Loop_Operate_Depth : begin
      if(looping || looping_condition) begin
        alu_sel = ALU_SEL_Depth; // depth++/--
        operation = decoded_instr[0]; // if [, ++, ], --
        depth_en = 1; // reg = reg++/--
      end
    end
  endcase
end

// State Transitions on Clock
always @ (posedge clk) begin
	if (~nreset) current_state <= STATE_Fetch_Instr;
	else if (en) current_state <= next_state; //Only progress state if design is enabled
end

// State Transitions on Condition
always @ ( * ) begin
  next_state = current_state;
  case (current_state)
    STATE_Next_PC : begin
      next_state = STATE_Fetch_Instr;
    end
    STATE_Fetch_Instr : begin
      if(not_instr) // Not instr, skip to next pc
        next_state = STATE_Next_PC;
      else begin
	if(looping && ~(decoded_instr == 3'b100 || decoded_instr == 3'b101)) // looping and ignoring instrs that arent [/]
	  next_state = STATE_Next_PC;
        else if(decoded_instr == 3'b000 || decoded_instr == 3'b001) // +/-
	  next_state = STATE_Sum_Sub_Fetch_Data;
        else if(decoded_instr == 3'b010 || decoded_instr == 3'b011) // >/<
	  next_state = STATE_Shift_Reg;
        else if (decoded_instr == 3'b100 || decoded_instr == 3'b101) begin // [/]
	  if (looping) next_state = STATE_Loop_Operate_Depth;
	  else next_state = STATE_Loop_Fetch_Data;
	end
      end
    end
    // +/-
    STATE_Sum_Sub_Fetch_Data : begin
      next_state = STATE_Sum_Sub_Operate_Data;
    end
    STATE_Sum_Sub_Operate_Data : begin
      next_state = STATE_Sum_Sub_Write_Data;
    end
    STATE_Sum_Sub_Write_Data : begin
      next_state = STATE_Next_PC;
    end
    // >/<
    STATE_Shift_Reg : begin
      next_state = STATE_Next_PC;
    end
    // [/]
    STATE_Loop_Fetch_Data : begin
      next_state = STATE_Loop_Operate_Depth;
    end
    STATE_Loop_Operate_Depth : begin
      next_state = STATE_Next_PC;
    end
  endcase
end

endmodule
