//DIVISION MODULE
module fpu_div(
    input [63:0] a,
    input [63:0] b,

    output [63:0] result
);

    //sign of result
    wire sign = a[63] ^ b[63];

    //wire according to IEEE 754 representation
    wire [10:0] exp_a = a[62:52];
    wire [10:0] exp_b = b[62:52];
    wire [51:0] frac_a = a[51:0];
    wire [51:0] frac_b = b[51:0];

    //for  normal & purely fractional number
    wire [53:0] mant_a = (|exp_a) ? {1'b1, frac_a} : {1'b0, frac_a};
    wire [53:0] mant_b = (|exp_b) ? {1'b1, frac_b} : {1'b0, frac_b};

    //multiplying the numerator by 2^53 to handle fixed-point division
    wire [106:0] dividend = mant_a << 53;
    wire [53:0] divisor = mant_b;
    wire [53:0] quotient = dividend / divisor;

    reg [10:0] exp_result;
    reg [53:0] norm_quot;

    always @(*) 
    begin
    exp_result = exp_a - exp_b + 1023;
    norm_quot = quotient;

    //Left-shift mantissa until MSB is 1
    while (norm_quot[53] == 0 && norm_quot != 0) 
        begin
            norm_quot = norm_quot << 1;
            exp_result = exp_result - 1;
        end
    end

    //next 52 bit after MSB will be fraction
    wire [51:0] frac_result = norm_quot[52:1];

    //for divide by zero & zero divide by something case
    assign result = (mant_b == 0) ? 64'h7FF0000000000000 : (mant_a == 0) ? 64'b0 : {sign, exp_result, frac_result};

endmodule