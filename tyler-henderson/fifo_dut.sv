`default_nettype none


module FIFO
#(parameter D_WIDTH = 4,
  parameter DEPTH   = 4)

 (input  wire clk, rst,
  input  wire wr_req, rd_req,
  input  wire [D_WIDTH-1:0] data_in,
  input wire start_tracking, stop_tracking,

  output logic wr_ack, rd_ack,
  output logic full, empty,
  output logic [D_WIDTH-1:0] data_out);


    logic [D_WIDTH-1:0] mem [DEPTH-1:0];
    logic [$clog2(DEPTH):0] count;
    logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    wire hsk_in = wr_req & wr_ack;
    wire hsk_out = rd_req & rd_ack;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0; 
        end
        else begin

            if (hsk_in) begin
                mem[wr_ptr] <= data_in;
                wr_ptr      <= wr_ptr + 1;
            end
            else if (hsk_out) begin
                data_out <= mem[rd_ptr];
                rd_ptr   <= rd_ptr + 1;
            end
       end
    end
    always_ff @(posedge clk, posedge rst) begin
        if (rst) count <= '0;
        else if (hsk_in)  count <= count + 1;
        else if (hsk_out) count <= count - 1;
    end
    assign wr_ack = wr_req & ~full;
    assign rd_ack = rd_req & ~empty;
    assign full = (count == DEPTH);
    assign empty = (count == 0);
    
endmodule: FIFO

