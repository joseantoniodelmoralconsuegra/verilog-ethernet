module iverilog_dump();
initial begin
    $dumpfile("eth_mac_10g.fst");
    $dumpvars(0, eth_mac_10g);
end
endmodule
