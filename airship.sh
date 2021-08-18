#!/usr/bin/env bash
port=7777
key_file="${HOME}/.airship-key"
ipaddr_prefix="192.168."
ipaddr_prefix_escaped=`echo $ipaddr_prefix | sed 's/\./\\\./g'`
ipaddr=`ifconfig | sed -n -E 's/^[[:space:]]+inet ('"$ipaddr_prefix_escaped"'[[:digit:]]{1,3}\.[[:digit:]]{1,3}) .*/\1/p'`

usage () {
	script=`basename $0`
	echo "usage: $script send <file>"
	echo "       $script get  <ip_addr>"
	echo "       $script key  <import|export|generate>"
	exit
}

# two arguments should always be present
if [ -z "$1" ] || [ -z "$2" ]; then
	usage
fi

action=$1
subaction=$2

# check for valid action
if [ -z $(echo $action | sed -n -E 's/^(send|get|key)$/&/p') ]; then
	usage
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

write_key () {
	local key=$1
	
	if [ -f "$key_file" ]; then
		# prompt for overwrite if file exists
		echo -n "$key_file exists. Overwrite? [y/N] "
		read answer

		# check with regex
		if [ -z "$(echo $answer | sed -n -E 's/^y$/&/ip')" ]; then
			# negative confirmation - exit function
			return 1
		fi
	fi

	echo -n "writing ${key_file}..."
	echo "$key" > $key_file
	echo "done"
}

read_key () {
	local key=""
	if [ ! -f "$key_file" ]; then
		echo "$key_file missing. run \"key generate\" for encrypted transfers."
		exit 1
	else
		echo $(head -n 1 "$key_file")
	fi
}

# TODO - check for presence of subaction

# handle keys first since they affect how all other actions operate
if [ "$action" = "key" ]; then

	# generate new key and write if no key file is present
	# otherwise, confirm via prompt
	if [ "$subaction" = "generate" ]; then
		echo -n "generating new key..."
		key=$(generate_key)
		echo "done"
		
		# file checks handled within function
		write_key $key
	fi

	if [ "$subaction" = "export" ]; then
		echo $(read_key)
		exit
	fi
	
	if [ "$subaction" = "import" ]; then
		echo -n "enter key: "
		read key
		echo -n "writing ${key_file}..."
		write_key $key
		echo "done"
	fi

	exit
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
