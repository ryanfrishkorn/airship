# Airship

### Simple BASH script to mimic the functionality of AirDrop using netcat. This is useful when admins install weird security software that screws up your workflow.

![airship](https://github.com/ryanfrishkorn/airship/blob/master/assets/airship.jpg?raw=true)

## Requirements
- netcat (MacOS is preinstalled)
- ccrypt (widely available)

## Installation
I usually create a `bin` directory within `$HOME`. Clone the repository somewhere out of the way, and make a symlink with the name of your choosing.

```
mkdir ~/bin
cd ~/bin
ln -s ~/airship/airship.sh airship
```
Make sure to add ~/bin to the end of your `$PATH` environmental variable.

## Usage
There are two main subcommands:
```
airship send my-file.png
airship get  192.168.0.8
```

There is also a key management subcommand:
```
airship key generate
airship key import
airship key export
```

Note that machines must have matching keys in order to properly decrypt.

If you attempt to get a filename that already exists on the system, the script will abort rather than overwrite. Delete your **own** data, please.

## Caution
This is a minimalist script that relies on `BASH`, `netcat`, and `ccrypt` for optional encryption. The goal is to be as simple and painless as possible, but that comes with certain compromises. The filename is negotiated by sending it on the first transfer.
