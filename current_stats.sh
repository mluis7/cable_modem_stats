#!/bin/bash
#
# Create graphic with bandwidth.
#

script_name=$(basename $0)
function print_usage(){
	echo "Create down stream speed graphic for the given time range, last 24 hs by default." 
	echo "Usage: $script_name [-d <data source file>] [-s <start time>] [-e <end time>] [-o <output image path>]"
	echo "Examples: $script_name -d $HOME/bin/arris-download.rrd -s '14:00' -e '23:00' -o $HOME/tmp/myrouter-000.png"
	echo "          $script_name -d $HOME/bin/TG862G-download.rrd -s '14:00' -o $HOME/tmp/myrouter-000.png"
}

rfile="$HOME/bin/arris-downstream.rrd"
ofile="$HOME/tmp/arris-downstream-24h.png"
trange1=-86400
trange2=-1

while getopts d:e:ho:s: arg
do
  case $arg in
    d) rfile=$OPTARG;;
    e) trange2="$(date -d "$OPTARG" '+%s')";;
	o) ofile=$OPTARG;;
	s) trange1="$(date -d "$OPTARG" '+%s')";;
    h) print_usage; exit;;
    *) 
        echo "Invalid option $arg"
        print_usage
        exit 1;;
  esac
done

topt="--start $trange1 --end $trange2"
opts="--width=900 --height=600 --base=1000 --vertical-label='bits/s' --legend-position=east --interlaced"

#echo "rrdtool graph $ofile $opts  $topt"

rrdtool graph "$ofile" $opts $topt \
DEF:in1=$rfile:stream1:AVERAGE \
DEF:in2=$rfile:stream2:AVERAGE \
DEF:in3=$rfile:stream3:AVERAGE \
DEF:in4=$rfile:stream4:AVERAGE \
DEF:in5=$rfile:stream5:AVERAGE \
DEF:in6=$rfile:stream6:AVERAGE \
DEF:in7=$rfile:stream7:AVERAGE \
DEF:in8=$rfile:stream8:AVERAGE \
CDEF:TotalIn=in1,in2,in3,in4,in5,in6,in7,in8,+,+,+,+,+,+,+,8,* \
LINE2:TotalIn#6a5acd:"Total bits/s\n" \
COMMENT:"\s" \
CDEF:in1b=in1,8,* \
CDEF:in2b=in2,8,* \
CDEF:in3b=in3,8,* \
CDEF:in4b=in4,8,* \
CDEF:in5b=in5,8,* \
CDEF:in6b=in6,8,* \
CDEF:in7b=in7,8,* \
CDEF:in8b=in8,8,* \
LINE1:in1b#00FF00:"Stream 1\n" \
LINE1:in2b#FF0000:"Stream 2\n" \
LINE1:in3b#0000FF:"Stream 3\n" \
LINE1:in4b#FF00FF:"Stream 4\n" \
LINE1:in5b#EF0000:"Stream 5\n" \
LINE1:in6b#0000EF:"Stream 6\n" \
LINE1:in7b#DF0000:"Stream 7\n" \
LINE1:in8b#1C3135:"Stream 8\n" \
COMMENT:"\s" \
GPRINT:TotalIn:AVERAGE:"Avg\:%4.2lf%s\n" \
GPRINT:TotalIn:MAX:"Max\:%4.2lf%s\n" \
