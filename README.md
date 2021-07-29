# Airship
Simple BASH scripts to mimic the functionality of AirDrop using netcat. This is useful when admins install weird security software that screws up your workflow.

## Installation
I usually create a `bin` directory within `$HOME`. Clone the repository somewhere out of the way, and make a symlink with the name of your choosing.

```
mkdir ~/bin
cd ~/bin
ln -s ~/airship/airship.sh airship
```
Make sure to add ~/bin to the end of your `$PATH` environmental variable.
