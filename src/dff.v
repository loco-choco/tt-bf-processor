/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module dff (
    input wire clk,
    input wire [7:0] d,
    input wire nreset, //Reset on low
    output reg [7:0] q;
);

always @ (posedge clk or negedge nreset) begin
    if(~nreset)
	q <= 0;
    else
	q <= d;
end

endmodule
