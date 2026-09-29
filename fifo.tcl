clear -all

analyze -sv fifo_dut.sv
analyze -sv fifo_tb.sv
analyze -sv fifo_bind.sv


elaborate -disable_auto_bbox \
    -top FIFO

reset rst

clock clk 

#reset -expression rst

set_engine_mode {B M G Hps Hts Tri}
