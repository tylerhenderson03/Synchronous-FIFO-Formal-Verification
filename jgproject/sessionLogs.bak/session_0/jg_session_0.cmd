# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2023.12
# platform  : Linux 5.14.0-687.10.1.el9_8.0.1.x86_64
# version   : 2023.12 FCS 64 bits
# build date: 2023.12.19 17:39:24 UTC
# ----------------------------------------
# started   : 2026-09-26 23:28:11 PDT
# hostname  : flip1.engr.oregonstate.edu.(none)
# pid       : 3061111
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:36443' '-style' 'windows' '-data' 'AAABHnicVY+9CsJAEIS/KPY+h2DEPq2dElQQuxDORIWQE2MQbPRRfZM4e5IiuzCzf3O7FwHJu+s6go1fgilrNuxYCVMOYjiyoKakEZ9puVLJC2U5y4AtDy44PCfVbc6panGtyCYrqVzIG2GsXi5NsOj7Z5KIoVk+Gla2nwHDpBf3IyaYMdf7dqXnSab7bG/LTe65a3OhCzL9cB/+XOq6Up1YHSeV2Q856CYU' '-proj' '/nfs/stak/users/hendetyl/eecs/ece499HW_Verif/quiz2-fifo/jgproject/sessionLogs/session_0' '-init' '-hidden' '/nfs/stak/users/hendetyl/eecs/ece499HW_Verif/quiz2-fifo/jgproject/.tmp/.initCmds.tcl' 'fifo.tcl'
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
prove -bg -all
