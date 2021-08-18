#!/bin/bash
port=7777
ipaddr_prefix="192.168."
ipaddr_prefix_escaped=`echo $ipaddr_prefix | sed 's/\./\\\./g'`
ipaddr=`ifconfig | sed -n -E 's/^[[:space:]]+inet ('"$ipaddr_prefix_escaped"'[[:digit:]]{1,3}\.[[:digit:]]{1,3}) .*/\1/p'`

# two arguments should always be present
if [ -z "$1" ] || [ -z "$2" ]; then
	script=`basename $0`
	echo "usage: $script send <file>"
	echo "       $script get  <ip_addr>"
	exit 1
fi

action=$1

# check actions
if [ "$action" != "send" ] && [ "$action" != "get" ]; then
	echo "acceptable actions are: send, get"
	exit 1
fi

generate_key () {
	local key=""
	until [ ${#key} -eq 16 ]; do
		local c=$(head -c 1 /dev/urandom | sed -n -e 's/[a-zA-Z0-9]/&/p' 2>/dev/null)
		if [ -n $c ]; then
			# append matching character
			key="${key}${c}"
		fi
	done

	echo $key
}

# verify and prepare ccrypt keys
if [ ! -f "${HOME}/.airship-key" ]; then
	echo -n "generating new airship key..."
	# generate 16 digit key
	key="$(generate_key)"
	echo "done"
	echo "new key: $key"
fi

if [ "$action" = "send" ]; then
	file_tx=$2
	file_tx_basename=`basename "$2"`

	if [ ! -r "$file_tx" ]; then
		echo "error reading file $file_tx"
		exit 1
	fi

	cmd_tx="nc -l $port < \"$file_tx\""
	cmd_rx="airship get $ipaddr"
	cmd_negotiate="echo \"$file_tx_basename\" | nc -l $port"

	echo "receive command: $cmd_rx"
	
	# file name negotiation
	echo -n "negotiating on port $port..."
	# execute nc to give filename
	eval "$cmd_negotiate"

	if [ $? = 0 ]; then
		echo "success"
	else
		echo "failed"
		exit 1
	fi

	# file transfer
	echo -n "listening on port $port..."
	# execute nc to send
	eval "$cmd_tx"

	if [ $? = 0 ]; then
		echo "sent"
	else
		echo "error"
		exit 1
	fi
fi

if [ "$action" = "get" ]; then
	ipaddr_remote=$2
	echo -n "negotiating with $ipaddr_remote on port $port..."
	cmd_negotiate="nc $ipaddr_remote $port"
	file_rx=`$cmd_negotiate`
	if [ $? = 0 ]; then
		echo "success"
	else
		echo "fail"
		exit 1
	fi

	echo -n "writing to \"$file_rx\"..."
	# do not overwrite existing files
	if [ -f "$file_rx" ]; then
		echo "file already exists, aborting"
		exit 1
	fi

	cmd_rx="nc $ipaddr_remote $port > \"$file_rx\""
	# get the file
	eval "$cmd_rx"
	if [ $? = 0 ]; then
		echo "success"
	else
		echo "fail"
	fi
fi
