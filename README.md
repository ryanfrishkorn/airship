# Airship
Simple BASH scripts to mimic the functionality of AirDrop using netcat. This is useful when admins install weird security software that screws up your workflow.
![airship](https://github.com/ryanfrishkorn/airship/blob/image/assets/airship.jpg?raw=true)

## Installation
I usually create a `bin` directory within `$HOME`. Clone the repository somewhere out of the way, and make a symlink with the name of your choosing.

```
mkdir ~/bin
cd ~/bin
ln -s ~/airship/airship.sh airship
```
Make sure to add ~/bin to the end of your `$PATH` environmental variable.

## Usage
There are basically to subcommands:
```
airship send my-file.png
airship get  192.168.0.8
```
If you attempt to get a filename that already exists on the system, the script will abort rather than overwrite. Delete your **own** data, please.

## Caution
This is a minimalist script that relies entirely on `BASH` and `netcat`. The goal is to be as simple and painless as possible, but that comes with certain compromises. **ALL DATA IS UNENCRYPTED!** The filename is negotiated by sending it on the first transfer. If we had to type port numbers and filenames, it would defeat the purpose. The script is not designed to check or escape filenames yet, so avoid using complex filenames. This can be improved later.
