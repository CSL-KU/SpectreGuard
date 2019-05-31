set terminal pdfcairo font "Gill Sans,16" linewidth 2 rounded #fontscale 1.0

set style line 80 lt rgb "#808080"
# Line style for grid
set style line 81 lt 0  # dashed
set style line 81 lt rgb "#808080"  # grey
set style line 82 lt 0  # dashed
set style line 82 lt rgb "#000000"  # grey

set grid back linestyle 81
set border 1 back linestyle 80 
set xtics nomirror
set ytics nomirror

#set style line 1 lt rgb "#A00000" lw 2 pt 1
#set style line 2 lt rgb "#00A000" lw 2 pt 6
#set style line 3 lt rgb "#5060D0" lw 2 pt 2
#set style line 4 lt rgb "#F25900" lw 2 pt 9

set style line 1 lt rgb "#000000" lw 2 pt 1
set style line 2 lt rgb "#000040" lw 2 pt 6
set style line 3 lt rgb "#000080" lw 2 pt 2
set style line 4 lt rgb "#0000a0" lw 2 pt 9

set yrange [0:3.5]

# set xtics nomirror rotate by -40 # scale 0 font ",24"
set ylabel "Normalized Execution Time" offset 2
set style data histogram
set key at 0.5,3.3
set key samplen 1 width 2
set key autotitle columnhead
set boxwidth 1
set arrow from -1,1 to 4,1 nohead lt 2
# set arrow from 0.6,0 to 0.6,1.4 nohead lt 1

# set label "4.99" at 1.45,5 font ",16" front
set style fill pattern
plot  "artifacts/graphs/synthetic/synthetic-perf.dat" using 2:xticlabel(1) fs pattern 0 lt -1,\
       ''          using  5:xticlabel(1) fs pattern 1 lt -1,\
       ''          using  6:xticlabel(1) fs pattern 2 lt -1,\
       ''          using  3:xticlabel(1) fs pattern 3 lt -1,\
       ''          using  4:xticlabel(1) fs pattern 4 lt -1
