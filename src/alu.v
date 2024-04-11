/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module mux4  (
    input wire[1:0] operation,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] result
);

if(!operation)
  result <= a + b;
else
  result <= a - b;

endmodule
