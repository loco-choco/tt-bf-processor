/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module mux2  (
    input wire sel,
    input wire [7:0] in_0,
    input wire [7:0] in_1,
    output wire [7:0] out
);

if(sel)
  out <= in_1;
else
  out <= in_0;

endmodule
