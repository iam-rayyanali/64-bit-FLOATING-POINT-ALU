//ADDITION & SUBTRACTION MODULE
module fpu_add_sub (
    input  [63:0] a,
    input  [63:0] b,
    input  op,  // 0 = add, 1 = sub
    output reg [63:0] result,
    output reg invalid
);

    // Internal unpacked components
    reg sign_a, sign_b;
    reg [10:0] exp_a, exp_b;
    reg [52:0] mant_a, mant_b;
    reg [10:0] exp_diff;
    reg [10:0] exp_common;
    reg [53:0] mant_res;
    reg res_sign;
    reg [52:0] norm_mant;
    reg [10:0] norm_exp;

    always @(*) begin
        invalid = 0;

        // Unpack input a
        sign_a = a[63];
        exp_a = a[62:52];
        mant_a = (exp_a == 0) ? {1'b0, a[51:0]} : {1'b1, a[51:0]};  // handle denormals

        // Unpack input b
        sign_b = b[63] ^ op; // flip sign if subtraction
        exp_b = b[62:52];
        mant_b = (exp_b == 0) ? {1'b0, b[51:0]} : {1'b1, b[51:0]};

        // Handle NaN
        if ((exp_a == 11'h7FF && mant_a[51:0] != 0) || (exp_b == 11'h7FF && mant_b[51:0] != 0)) begin
            result = 64'hFFFFFFFFFFFFFFFF; // NaN
            invalid = 1;
        end
        // Handle Inf
        else if (exp_a == 11'h7FF || exp_b == 11'h7FF) begin
            result = 64'h7FF0000000000000; // +Infinity (simplified)
        end
        else begin
            // Align mantissas
            if (exp_a > exp_b) begin
                exp_diff = exp_a - exp_b;
                mant_b = mant_b >> exp_diff;
                exp_common = exp_a;
            end else begin
                exp_diff = exp_b - exp_a;
                mant_a = mant_a >> exp_diff;
                exp_common = exp_b;
            end

            // Perform operation
            if (sign_a == sign_b) begin
                mant_res = mant_a + mant_b;
                res_sign = sign_a;
            end else begin
                if (mant_a > mant_b) begin
                    mant_res = mant_a - mant_b;
                    res_sign = sign_a;
                end else begin
                    mant_res = mant_b - mant_a;
                    res_sign = sign_b;
                end
            end

            // Normalize result
            norm_exp = exp_common;
            norm_mant = mant_res[52:0];
            if (mant_res[53]) begin
                norm_mant = mant_res[53:1];
                norm_exp = norm_exp + 1;
            end else begin
                while (norm_mant[52] == 0 && norm_exp > 0) begin
                    norm_mant = norm_mant << 1;
                    norm_exp = norm_exp - 1;
                end
            end

            // Assemble result
            result = {res_sign, norm_exp, norm_mant[51:0]};
        end
    end
endmodule
