module cocotb_iverilog_dump();
initial begin
    $dumpfile("sim_build/eth_mac_40g.fst");
    $dumpvars(0, eth_mac_40g);
end
endmodule