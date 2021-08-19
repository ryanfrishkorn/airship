#!/usr/bin/env bash
port=7777
encryption=false
key_file="${HOME}/.airship"
ipaddr_prefix="192.168."
ipaddr_prefix_escaped=${ipaddr_prefix//\./\\\.}
ipaddr=$(ifconfig | sed -n -E 's/^[[:space:]]+inet ('"$ipaddr_prefix_escaped"'[[:digit:]]{1,3}\.[[:digit:]]{1,3}) .*/\1/p')

usage () {
	script=$(basename "$0")
	echo "usage: $script send <file>"
	echo "       $script get  <ip_addr>"
	echo "       $script key  <import|export|generate>"
	exit
}

generate_key () {
	local key=""
	until [ ${#key} -eq 16 ]; do
		local c
		c=$(head -c 1 /dev/urandom | sed -n -e 's/[a-zA-Z0-9]/&/p' 2>/dev/null)
		if [ -n "$c" ]; then
			# append matching character
			key="${key}${c}"
		fi
	done

	echo "$key"
}

write_key () {
	local key=$1
	
	if [ -f "$key_file" ]; then
		# prompt for overwrite if file exists
		echo -n "$key_file exists. Overwrite? [y/N] "
		read -r answer

		# check with regex
		# TODO check parsing
		if [ -z "$(echo "$answer" | sed -n -E 's/^y$/&/ip')" ]; then
			# negative confirmation - exit function
			echo "aborted"
			return 1
		fi
	fi

	echo -n "writing ${key_file}..."
	echo "$key" > "$key_file"
	echo "done"
}

read_key () {
	local key=""
	if [ ! -f "$key_file" ]; then
		echo "$key_file missing. run \"key generate\" for encrypted transfers."
		exit 1
	else
		head -n 1 "$key_file"
	fi
}

check_key () {
	if [ ! -f "$key_file" ]; then
		echo "WARNING: Key file is missing. Transfers will be in plaintext!"
	fi
}

# two arguments should always be present
if [ -z "$1" ] || [ -z "$2" ]; then
	usage
fi

# assign main action
action=$1

# check for valid action
if [ -z "$(echo "$action" | sed -n -E 's/^(send|get|key)$/&/p')" ]; then
	usage
fi

# enable encryption if airship key is present
if [ -f "$key_file" ]; then
	encryption=true
fi

# handle keys first since they affect how all other actions operate
if [ "$action" = "key" ]; then

	# generate new key and write if no key file is present
	# otherwise, confirm via prompt
	if [ "$2" = "generate" ]; then
		echo -n "generating new key..."
		key=$(generate_key)
		echo "done"
		
		# file checks handled within function
		write_key "$key"
	fi

	if [ "$2" = "export" ]; then
		read_key
		exit
	fi
	
	if [ "$2" = "import" ]; then
		echo -n "Enter key: "
		read -r key
		echo -n "writing ${key_file}..."
		write_key "$key"
		echo "done"
	fi

	exit
fi

if [ "$action" = "send" ]; then
	file_tx=$2
	file_tx_basename=$(basename "$2")

	# check for encryption key and generate warning
	check_key

	if [ ! -r "$file_tx" ]; then
		echo "error reading file $file_tx"
		exit 1
	fi

	if [ $encryption = "true" ]; then
		cmd_tx="cat \"$file_tx\" | ccrypt -e -k \"$key_file\" | nc -l $port"
		cmd_negotiate="echo \"$file_tx_basename\" | ccrypt -e -k \"$key_file\" | nc -l $port"
	else
		cmd_tx="nc -l $port < \"$file_tx\""
		cmd_negotiate="echo \"$file_tx_basename\" | nc -l $port"
	fi
	# for human suggestion
	cmd_rx="airship get $ipaddr"

	echo "receive command: $cmd_rx"
	
	# file name negotiation
	echo -n "negotiating on port $port..."
	
	# execute nc to give filename
	if eval "$cmd_negotiate"; then
		echo "success"
	else
		echo "failure"
		exit 1
	fi

	# execute nc for file transfer
	echo -n "listening on port $port..."
	if eval "$cmd_tx"; then
		echo "sent"
	else
		echo "failure"
		exit 1
	fi
fi

if [ "$action" = "get" ]; then
	ipaddr_remote=$2
	echo "negotiating with $ipaddr_remote on port $port..."
	if [ $encryption = "true" ]; then
		cmd_negotiate="nc $ipaddr_remote $port | ccrypt -d -k \"$key_file\""
	else
		cmd_negotiate="nc $ipaddr_remote $port"
	fi
	# negotiate file name
	if file_rx=$(eval "$cmd_negotiate"); then
		echo "success"
	else
		echo "failure"
		exit 1
	fi

	echo -n "writing to \"$file_rx\"..."
	# do not overwrite existing files
	if [ -f "$file_rx" ]; then
		echo "file already exists, aborting"
		exit 1
	fi

	if [ $encryption = "true" ]; then
		cmd_rx="nc $ipaddr_remote $port | ccrypt -d -k \"$key_file\" > \"$file_rx\""
	else
		cmd_rx="nc $ipaddr_remote $port > \"$file_rx\""
	fi

	# sleep after name negotiate to be sure sender is ready
	sleep 1

	# get the file
	if eval "$cmd_rx"; then
		echo "success"
	else
		echo "failure"
		exit 1
	fi
fi
