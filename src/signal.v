/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module signal (
    input wire [7:0] in,
    output wire signal
);

assign signal <= in >= 0;

endmodule
