/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module mux4  (
    input wire[1:0] sel,
    input wire [7:0] in_0,
    input wire [7:0] in_1,
    input wire [7:0] in_2,
    input wire [7:0] in_3,
    output wire [7:0] out
);

always @ (in_0 or in_1 or in_2 or in_3 or sel) begin
  case (sel)
    2'b00 : out <= in_0;
    2'b01 : out <= in_0;
    2'b10 : out <= in_0;
    2'b11 : out <= in_0;
end

endmodule
