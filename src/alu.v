/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module alu  (
    input wire operation,
    input wire [12:0] a,
    input wire [12:0] b,
    output reg [12:0] result
);

always @ ( * ) begin
  if(~operation)
    result = a + b;
  else
    result = a - b;
end
endmodule
