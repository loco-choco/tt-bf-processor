/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module mux4  (
    input wire[1:0] sel,
    input wire [12:0] in_0,
    input wire [12:0] in_1,
    input wire [12:0] in_2,
    input wire [12:0] in_3,
    output reg [12:0] out
);

always @ ( * ) begin
  case (sel)
    2'b00 : out = in_0;
    2'b01 : out = in_1;
    2'b10 : out = in_2;
    2'b11 : out = in_3;
  endcase
end

endmodule
