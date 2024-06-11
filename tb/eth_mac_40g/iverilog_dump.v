module iverilog_dump();
initial begin
    $dumpfile("eth_mac_40g.fst");
    $dumpvars(0, eth_mac_40g);
end
endmodule
