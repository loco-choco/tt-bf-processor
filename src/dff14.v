/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module dff14 (
    input wire clk,
    input wire en,
    input wire [12:0] d,
    input wire nreset, //Reset on low
    output reg [12:0] q
);

always @ (posedge clk) begin
    if(~nreset)
	q <= 0;
    else if (en)
	q <= d;
end

endmodule
