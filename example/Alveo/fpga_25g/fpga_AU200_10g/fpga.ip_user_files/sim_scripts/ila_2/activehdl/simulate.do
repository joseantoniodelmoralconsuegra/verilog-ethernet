transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+ila_2  -L xpm -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O2 xil_defaultlib.ila_2 xil_defaultlib.glbl

do {ila_2.udo}

run

endsim

quit -force
