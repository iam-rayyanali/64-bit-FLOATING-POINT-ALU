//floating point unit 
//capable of preforming addition, subtraction, multiplication & division.
//here i used double precision format of IEEE 754 which has 64 bit representation.
module fpu (
    input [63:0] a,
    input [63:0] b,
    input [1:0] op,// 00:add 01:sub 10:mul 11:div

    output reg [63:0] result
    );

    wire[63:0] add_sub_result, mul_result, div_result;

    //instantiation of adder module which also used for subtraction in accordance with sign of a & b
    fpu_add_sub add_sub_unit(.a(a), .b(b), .op(op[0]), .result(add_sub_result));

    //instantiation of multiplier
    fpu_mul mul_unit(.a(a), .b(b), .result(mul_result));

    //instantiation of divider
    fpu_div div_unit(.a(a), .b(b), .result(div_result));

    //assigning result according to "op"
    always@(*) 
        begin
            case (op)
            2'b00 : result = add_sub_result;
            2'b01 : result = add_sub_result;
            2'b10 : result = mul_result;
            2'b11 : result = div_result;
            endcase
        end

endmodule

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

// MULTIPLICATION MODULE
module fpu_mul (
		input [63:0] a,
		input [63:0] b,
		output Exception,Overflow,Underflow,
		output [63:0] result
		);

wire sign,product_round,normalised,zero;
wire [11:0] exponent,sum_exponent;
wire [51:0] product_mantissa;
wire [52:0] operand_a,operand_b;
wire [105:0] product,product_normalised; //106 Bits


assign sign = a[63] ^ b[63];

//Exception flag sets 1 if either one of the exponent is 2047.
assign Exception = (&a[62:52]) | (&b[62:52]);

//Assigining significand values according to Hidden Bit.
//If exponent is equal to zero then hidden bit will be 0 for that respective significand else it will be 1
assign operand_a = (|a[62:52]) ? {1'b1,a[51:0]} : {1'b0,a[51:0]};
assign operand_b = (|b[62:52]) ? {1'b1,b[51:0]} : {1'b0,b[51:0]};

//Calculating Product
assign product = operand_a * operand_b;	

//Ending 51 bits are OR'ed for rounding operation.
assign product_round = |product_normalised[51:0];  
assign normalised = product[105] ? 1'b1 : 1'b0;	

//Assigning Normalised value based on 106th bit
assign product_normalised = normalised ? product : product << 1;	

//Final Manitssa.
assign product_mantissa = product_normalised[104:53] + (product_normalised[52] & product_round); 
assign zero = Exception ? 1'b0 : (product_mantissa == 52'd0) ? 1'b1 : 1'b0;
assign sum_exponent = a[62:52] + b[62:52];
assign exponent = sum_exponent - 11'd1023 + normalised;

//If overall exponent is greater than 2047(max) then Overflow condition.
assign Overflow = ((exponent[11] & !exponent[10]) & !zero) ; 

//If sum of both exponents is less than 1023(bias) then Underflow condition.
assign Underflow = ((exponent[11] & exponent[10]) & !zero) ? 1'b1 : 1'b0; 
assign result = Exception ? 64'd0 : zero ? {sign,64'd0} : Overflow ? {sign,11'h7FF,52'd0} : Underflow ? {sign,63'd0} : {sign,exponent[10:0],product_mantissa};

endmodule

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
