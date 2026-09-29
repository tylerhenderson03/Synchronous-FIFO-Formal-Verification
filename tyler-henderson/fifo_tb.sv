`default_nettype none


module FIFO_tb
#(parameter D_WIDTH = 4,
  parameter DEPTH   = 4)

 (input  wire clk, rst,
  input  wire wr_req, rd_req,
  input  wire [D_WIDTH-1:0] data_in,
  input wire start_tracking,
  input wire stop_tracking, 

  input  wire wr_ack, rd_ack,
  input  wire full, empty,
  input  wire [D_WIDTH-1:0] data_out);

  ///////////////////////////
  // INCLUDE YOUR CODE HERE//
  ///////////////////////////

// from task #2
  RD_REQ: assert property (@(posedge clk) disable iff (empty) rd_req |-> rd_ack);
  RD_ACK: assert property (@(posedge clk) disable iff (empty) rd_ack |-> rd_req);

  WR_REQ: assert property (@(posedge clk) disable iff(full) wr_req |-> wr_ack);
  WR_ACK: assert property (@(posedge clk) disable iff(full) wr_ack |-> wr_req);

// new, for task #3
  logic valid_wr, valid_rd;
  assign valid_wr = wr_req & wr_ack;
  assign valid_rd = rd_req & rd_ack;

  logic [$clog2(DEPTH):0] counter;
  always @(posedge clk or posedge rst) begin
	if(rst) counter <= 0;
    else if (valid_wr) counter <= counter + 1;
    else if (valid_rd) counter <= counter - 1;
    else counter <= counter;
  end

  FIFO_EMPTY: assert property     (@(posedge clk) disable iff (rst) counter == 0 |-> empty);
  FIFO_EMPTY_COMPLEMENT: assert property     (@(posedge clk) disable iff (rst) empty |-> counter == 0);
  FIFO_NOT_EMPTY: assert property (@(posedge clk) disable iff (rst) (counter <= 8 && counter > 0) |-> ~empty);
  FIFO_FULL: assert property      (@(posedge clk) disable iff (rst) counter == DEPTH |-> full);
  FIFO_FULL_COMPLEMENT: assert property      (@(posedge clk) disable iff (rst) full |-> counter == DEPTH);
  FIFO_NOT_FULL: assert property  (@(posedge clk) disable iff (rst) (counter < DEPTH && counter >= 0) |-> ~full);

  NO_OVERFLOW:  assert property   (@(posedge clk) disable iff (rst) full  |-> ~valid_wr);
  NO_UNDERFLOW: assert property   (@(posedge clk) disable iff (rst) empty |-> ~valid_rd);

// task 4
  logic [D_WIDTH-1:0] shift_reg [DEPTH-1:0];
  logic [3:0] i;
  always_ff @(posedge clk or posedge rst) begin
    if(rst) begin // do nothing, as per the assignment doc
    end
    else begin
        if(valid_wr) begin // valid write
            // use the full/empty counter to index into the correct shift register entry and update it
            shift_reg[counter] <= data_in; // first data written to index 0, then 1, then 2
        end
        if(valid_rd) begin // valid read
            // all entries in the shift register should be shifted by one position
            for(i = 0; i < DEPTH-1; i = i+1) begin
                shift_reg[i] <= shift_reg[i+1];
            end
        end
    end
  end

// single transation model

// if our tb counter shows the FIFO is full, we should also see that the DUT says it is full too
  a_full: assert property(@(posedge clk) disable iff(rst) reg_counter == DEPTH |-> full);

// if our tb counter shows the FIFO is empty, we should also see that the DUT says it is empty too
  a_empty: assert property(@(posedge clk) disable iff(rst)  reg_counter == 0 |-> empty);

/*
valid wr/rd only occurs when a wr/rd_req is met with a wr/rd_ack on the same clock cycle.
wr/rd_ack's are driven with C.L.
*/
  a_valid_wr: assert property(@(posedge clk) disable iff(rst)             wr_req |-> wr_ack);
  a_valid_wr_complement: assert property(@(posedge clk) disable iff(rst)  wr_ack |-> wr_req);
  a_valid_rd: assert property(@(posedge clk) disable iff(rst)             rd_req |-> rd_ack);
  a_valid_rd_complement: assert property(@(posedge clk) disable iff(rst)  rd_ack |-> rd_req);


// assume that we can see either a wr_req, OR a rd_req, OR neither, but not both
// since wr_req and rd_req are inputs, we use an "assume" property to tell jasper how to guide the test cases we input here
  a_no_simulatneous_wr_rd: assume property(@(posedge clk) !(wr_req & rd_req));

/*
at ANY edge of the clk, if we see start tracking asserted,
this means on the next clock cycle, we should see it continue to be
asserted throughout the functionality of our program
*/
  as_st_stable: assume property(@(posedge clk) start_tracking |=> $stable(start_tracking));

/*
if we see start_tracking rise on a given clk cycle (with the previous property, it will only rise once)
then we should also see that when it has risen, that wr_ack should have been
asserted as well for a valid write to the FIFO/DUT
*/
  as_st_write: assume property (@(posedge clk) $rose(start_tracking) |-> valid_wr);
  as_st_track_din: assume property (@(posedge clk) $rose(start_tracking) |-> (data_in == track_me));

// asserts that the current value of counter is less than or equal to the previous value of counter
  a_counter_dec: assert property (@(posedge clk) disable iff(~start_tracking) start_tracking |=> ( ($past(counter) > counter) || ($past(counter) == counter) ));

/*
  do not track if "start_tracking" is de-asserted.
  if counter(number of elements in front of tracked element) is zero, and there's a rd_ack,
  then the popped element should equal our tracked element
*/
  a_popped: assert property (@(posedge clk) disable iff(~start_tracking) (counter == 0 & valid_rd) |=> (data_out == track_me));

// Spec no. 11: Verify that it is possible to start tracking an element
  start_track_element: cover property(@(posedge clk) start_tracking);

// Spec no. 14: Verify that done_tracking is never asserted before start_tracking
  start_before_done: assert property(@(posedge clk) ~start_tracking |-> ~done_tracking);

  reg [$clog2(DEPTH):0] reg_counter; // regular counter
  reg [$clog2(DEPTH):0] counter; // counter for number of packets in front of tracked packet

  logic valid_wr, valid_rd;
  assign valid_wr = wr_req & wr_ack;
  assign valid_rd = rd_req & rd_ack;

  bit done_tracking;
  always_ff @(posedge clk) begin
    if(rst) begin
      done_tracking <= 0;
    end
    else if((valid_rd) & (data_out == track_me) & (counter == 0)) begin
      done_tracking <= 1;
    end
  end

  // regular counter behaves like normal
  always_ff @(posedge clk, posedge rst) begin
    if (rst) reg_counter <= '0;
    else if (valid_wr)  reg_counter <= reg_counter + 1;
    else if (valid_rd) reg_counter <= reg_counter - 1;
  end

  // augmented counter to track no. of packets in front of arbitrary tracked packed (track_me)
  always_ff @(posedge clk, posedge rst) begin
    if (rst) counter <= '0;
    else if (start_tracking) begin // if start_tracking is asserted, packet has been sampled in. is it out of the FIFO yet?
		if (stop_tracking) counter <= counter; // should just be updating with '0' each time
		else if (valid_rd & ~empty & counter != '0) counter <= counter - 1; // only decrement when tracking the packet through the FIFO
		// counter now represents the "place" in the FIFO of the tracked packet, if '1', then it is the next packet to be read out.
    end
    else begin
      if (valid_wr & ~full)  counter <= counter + 1;
      else if (valid_rd & ~empty) counter <= counter - 1;
    end
  end

  reg [D_WIDTH-1:0] track_me;
  assume property ($stable(track_me));



endmodule: FIFO_tb
