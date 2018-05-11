#!/bin/bash
#
# create rrdtool data sources
#

script_name=$(basename $0)
rfile="$HOME/bin/arris-downstream.rrd"
tstart=$(date '+%s')
# Avoid spikes in graphs if CM is restarted
ds_type='DERIVE'
min=0
# Max value for a 32 bits counter
max=2147483647

function print_usage(){
	echo "Create rrdtool data source."
    echo "Usage  : $script_name -d <rrd filename> [-s <start time as Unix Epoch>] [-i]"
	echo "Example: $script_name -d $rfile -s $tstart"
}


get_info=0
while getopts d:his: arg
do
  case $arg in
    d) rfile=$OPTARG;;
	s) trange1=$(date -d "$OPTARG" '+%s');;
    h) print_usage; exit;;
    i) get_info=1;;
    *) 
        echo "Invalid option $arg"
        print_usage
        exit 1;;
  esac
done

if [ "$get_info" -eq 1 ]; then
	rrdtool info $rfile
	exit
fi

echo "Creating rrd data source as $rfile - start time: $tstart"
rrdtool create $rfile --start $tstart \
    DS:stream1:$ds_type:600:$min:$max \
    DS:stream2:$ds_type:600:$min:$max \
    DS:stream3:$ds_type:600:$min:$max \
    DS:stream4:$ds_type:600:$min:$max \
    DS:stream5:$ds_type:600:$min:$max \
    DS:stream6:$ds_type:600:$min:$max \
    DS:stream7:$ds_type:600:$min:$max \
    DS:stream8:$ds_type:600:$min:$max \
    RRA:AVERAGE:0.5:1:600 \
    RRA:AVERAGE:0.5:6:700 \
    RRA:AVERAGE:0.5:24:775 \
    RRA:AVERAGE:0.5:288:797 \
    RRA:MAX:0.5:1:600 \
    RRA:MAX:0.5:6:700 \
    RRA:MAX:0.5:24:775 \
    RRA:MAX:0.5:288:797 \

# Insert first empty record as creation timestamp
rrdtool update $rfile $((tstart+1)):0:0:0:0:0:0:0:0
