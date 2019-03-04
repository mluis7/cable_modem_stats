#!/bin/bash
#---------------------------------------------------------------------------------------
# Parse Arris TG862A status page using XPath and store results on rrd.
#---------------------------------------------------------------------------------------


host_name=$(hostname)
script_name="$(basename $0)[$$]"
ds="$HOME/bin/arris-downstream.rrd"
status_url="http://192.168.100.1/cgi-bin/status_cgi"

#---------------------------------------------------------------------------------------
# Print Help message
#---------------------------------------------------------------------------------------
function print_usage(){
cat << EOFU
SUMMARY:
    Parse Arris TG862A status page using XPath and store results on rrd.

OPTIONS:
	-d Data source file path. Optional, $ds by default.
	-u status page URL, default: http://192.168.100.1/cgi-bin/status_cgi
	-h This help.
EOFU
}

#---------------------------------------------------------------------------------------
# log messages with same format as /var/log/auth.log
# Format: <Timestamp> <hostname> <app name [PID]:> <message>
# Example: Jul 23 06:53:59 linux.local arris_stats.sh[2820]: Cable modem is down.
#---------------------------------------------------------------------------------------
function log_msg(){
 echo -e "$(date '+%b %d %H:%M:%S') $host_name $script_name $1"
}

#---------------------------------------------------------------------------------------
# Get cable modem status page
#---------------------------------------------------------------------------------------
function get_status(){
    wget --quiet "$status_url" -O -
}

#---------------------------------------------------------------------------------------
# Parse status page html using XPath and update data source.
#---------------------------------------------------------------------------------------
function record_down_streams(){
    
    stream_xpath="//table/tbody[tr[td[.='DCID']]]/tr[%d]/td[7]/text()"
    declare -a octets
    for i in {2..9};do
        sx=$(printf "$stream_xpath" $i)
        octets[$i]=$(echo "$1" | xmllint --html --recover --xpath "$sx" - 2>/dev/null)
    done

    t=$(date '+%s')
    update_val="$(printf '%d:%d:%d:%d:%d:%d:%d:%d:%d' $t ${octets[*]})"
    log_msg "Updating rrd: '$update_val'"
    rrdtool update "$ds" "$update_val"
}

# parse options
while getopts d:h arg
do
  case $arg in
    d) ds=$OPTARG;;
    u) status_url="$OPTARG";;
    h) print_usage; exit;;
    *) 
        echo "Invalid option $arg"
        print_usage
        exit 1;;
  esac
done

stats=$(get_status)

record_down_streams "$stats"

