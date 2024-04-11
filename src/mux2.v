/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module mux2  (
    input wire sel,
    input wire [7:0] in_0,
    input wire [7:0] in_1,
    output reg [7:0] out
);

always @ ( * ) begin
  if(sel)
    out = in_1;
  else
    out = in_0;
end

endmodule
