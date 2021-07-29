#!/bin/bash
port=7777
ipaddr=`ifconfig | sed -n -E 's/^[[:space:]]+inet (192\.168\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}) .*/\1/p'`

# handle arguments
if [ -z $1 ] || [ ! -r $1 ]; then
	script=`basename $0`
	echo "usage: $script <file>"
	exit 1
fi

send_file=$1
send_file_basename=`basename $1`

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
