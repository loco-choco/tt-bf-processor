/*
 * Copyright (c) 2024 Ivan Pancheniak
 * SPDX-License-Identifier: Apache-2.0
 */

module is_zero14  (
    input wire [12:0] in,
    output wire is_zero
);

assign is_zero = in == 0;

endmodule
