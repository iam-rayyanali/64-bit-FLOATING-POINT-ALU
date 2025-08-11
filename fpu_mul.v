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
