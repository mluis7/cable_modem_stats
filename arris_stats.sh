#!/bin/bash
#---------------------------------------------------------------------------------------
# Parse Arris TG862A status page using XPath and store results on rrd.
#---------------------------------------------------------------------------------------


host_name=$(hostname)
script_name="$(basename $0)[$$]"
ds="$HOME/tmp/arris-downstream.rrd"

#---------------------------------------------------------------------------------------
# Print Help message
#---------------------------------------------------------------------------------------
function print_usage(){
cat << EOFU
SUMMARY:
    Parse Arris TG862A status page using XPath and store results on rrd.

OPTIONS:
	-d Data source file path. Optional, $ds by default.
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
    wget --quiet "http://192.168.100.1/cgi-bin/status_cgi" -O -
}

#---------------------------------------------------------------------------------------
#
#---------------------------------------------------------------------------------------
function record_down_streams(){
    t=$(date '+%s')
    x="concat(//tbody[tr[td[.='DCID']]]/tr[2]/td[7]/text(), '_' , \
//tbody[tr[td[.='DCID']]]/tr[3]/td[7]/text(), '_', \
//tbody[tr[td[.='DCID']]]/tr[4]/td[7]/text())"

    # FIXME
    # a=($(xmllint --html --xpath 'concat(//tbody[tr[td[.="DCID"]]]/tr[8]/td[7]/text(), "_" ,//tbody[tr[td[.="DCID"]]]/tr[9]/td[7]/text())' ~/Documents/supercanal/Arris/2018-05-02-Touchstone-Status.html 2>/dev/null | tr '_' '\n'))
    # echo "${a[*]}"
    # printf "%s, '_', " "${a[@]}"
    stream_xpath="//table/tbody[tr[td[.='DCID']]]/tr[%d]/td[7]/text()"
    update_tpl="%s:%s"
    update_val="$t:"
    declare -a octets
    
    for i in {2..9};do
        sx=$(printf "$stream_xpath" $i)
        octets[$i]=$(echo "$1" | xmllint --html --recover --xpath "$sx" - 2>/dev/null)
    done
    for i in {2..9};do
        if [ "$i" -lt 9 ]; then
           update_val+="${octets[$i]}:"
        else
           update_val+="${octets[$i]}"
        fi
    done
    log_msg "Updating rrd: '$update_val'"
    rrdtool update "$ds" "$update_val"
}

# parse options
while getopts d:h arg
do
  case $arg in
    d) ds=$OPTARG;;
    h) print_usage; exit;;
    *) 
        echo "Invalid option $arg"
        print_usage
        exit 1;;
  esac
done

stats=$(get_status)

record_down_streams "$stats"

