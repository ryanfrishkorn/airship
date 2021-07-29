#!/bin/bash
port=7777
ipaddr_prefix="192.168."
ipaddr_prefix_escaped=`echo $ipaddr_prefix | sed 's/\./\\\./g'`
ipaddr=`ifconfig | sed -n -E 's/^[[:space:]]+inet ('"$ipaddr_prefix_escaped"'[[:digit:]]{1,3}\.[[:digit:]]{1,3}) .*/\1/p'`

# handle arguments
if [ -z $1 ] || [ -z $2 ]; then
	script=`basename $0`
	echo "usage: $script send <file>"
	echo "       $script get  <ip_addr>"
	exit 1
fi

action=$1
send_file=$2
send_file_basename=`basename $2`

# check actions
if [ "$action" != "send" ] && [ "$action" != "get" ]; then
	echo "acceptable actions are: send, get"
	exit 1
fi

if [ ! -r $send_file ]; then
	echo "error reading file $send_file"
	exit 1
fi

cmd_tx="nc -l $port < \"$send_file\""
cmd_rx="nc $ipaddr $port > \"$send_file_basename\""

echo "send command: $cmd_tx"
echo "receive command: $cmd_rx"
echo -n "listening on port $port..."

# execute nc to send
eval "$cmd_tx"

if [ $? = 0 ]; then
	echo "sent"
else
	echo "error"
	exit 1
fi
