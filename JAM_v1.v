module JAM (
input CLK,
input RST,
output reg [2:0] W,
output reg [2:0] J,
input [6:0] Cost,
output reg [3:0] MatchCount,
output reg [9:0] MinCost,
output reg Valid);

`define IDLE 2'b00
`define INPUT 2'b01
`define CAL 2'b10

integer i;

reg [9:0] cost_table [0:63];

reg [5:0] counter;
reg [1:0] current_state;
reg [1:0] next_state;

reg [7:0] mask;
reg [9:0] dp [0:255];
reg [3:0] same_min_ans [0:255];

wire [7:0] next_mask;
wire [9:0] new_dp;
wire [3:0] worker_number;

/////////////////////// input data ///////////////////////

// cost_table
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        for (i=0;i<64;i=i+1) begin
            cost_table[i] <= 10'b0;
        end
    end
    else if (current_state == `INPUT) begin
        cost_table[counter] <= Cost;
    end
end

// W
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        W <= 3'b0;
    end
    else if (next_state == `INPUT) begin
        if (&J)begin
            W <= W + 1'b1;
        end
    end
end

// J
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        J <= 3'b0;
    end
    else if (next_state == `INPUT) begin
        if (&J) begin
            J <= 3'b0;
        end
        else begin
            J <= J + 1'b1;
        end
    end
end

// counter
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        counter <= 6'b0;
    end
    else if (current_state == `INPUT) begin
        if (next_state == `CAL) begin
            counter <= 6'b0;
        end
        else begin
            counter <= counter + 1'b1;
        end
        
    end
    else if (current_state == `CAL) begin
        if (&counter[2:0]) begin
            counter <= 6'b0;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end
end

/////////////////////// calculate ///////////////////////

assign next_mask = mask | (1 << counter);
assign new_dp = dp[mask] + cost_table[(8 * (worker_number - 1) + counter)];
assign worker_number = next_mask[0] + next_mask[1] + next_mask[2] + next_mask[3] + 
                       next_mask[4] + next_mask[5] + next_mask[6] + next_mask[7];

// mask
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        mask <= 8'b0;
    end
    else if (current_state == `CAL) begin
        if (&counter[2:0]) begin
            mask <= mask + 1'b1;
        end
    end
end

// dp
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        dp[0] <= 10'b0;
        for (i=1;i<256;i=i+1) begin
            dp[i] <= 10'b1111111111;
        end
    end
    else if (current_state == `CAL) begin
        if (new_dp < dp[next_mask]) begin
            dp[next_mask] <= new_dp;
        end
    end
end

// same_min_ans
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        for (i=0;i<256;i=i+1) begin
            same_min_ans[i] <= 4'b0001;
        end
    end
    else if (current_state == `CAL) begin
        if (new_dp < dp[next_mask]) begin
            same_min_ans[next_mask] <= same_min_ans[mask];
        end
        else if (new_dp == dp[next_mask]) begin
            same_min_ans[next_mask] <= same_min_ans[next_mask] + same_min_ans[mask]; 
        end
    end
end

// Valid
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        Valid <= 1'b0;
    end
    else if (&{mask}) begin
        Valid <= 1'b1;
    end
end

/////////////////////// output ///////////////////////

// MinCost
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        MinCost <= 10'b0;
    end
    else if (&mask) begin
        MinCost <= dp[mask];
    end
end

// MatchCount
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        MatchCount <= 4'b0;
    end
    else if (&mask) begin
        MatchCount <= same_min_ans[mask];
    end
end

/////////////////////// finite state machine ///////////////////////

// current_state
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        current_state <= `IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

// next_state
always @(*) begin
    case (current_state)
        `IDLE:begin
            next_state = `INPUT;
        end
        `INPUT:begin
            next_state = (&counter) ? `CAL : `INPUT;
        end
        `CAL:begin
            next_state = `CAL;
        end
    endcase
end

endmodule
