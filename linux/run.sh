#!/bin/bash

name="rke2"
disk="18"
cpus="4"
ram="8"

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in

    -h) echo "
Info:
    You have to install Multipass before using the script.

Parameters:
    -name Give a name for your instance.
    -disk Specify disk size in GB. Recommended at least 18.
    -cpus Number of CPU cores. Recommended at least 4.
    -ram Specify amount of RAM memory in GB. Recommended at least 8.

Default:
    ./script.sh -name rke2 -ram 8 -cpus 4 -disk 18
      "
      exit 0 ;;
    -name)
      name="$2"
      shift
      shift ;;
    -disk)
      disk="$2"
      shift
      shift ;;
    -cpus)
      cpus="$2"
      shift
      shift ;;
    -ram)
      ram="$2"
      shift
      shift ;;
  esac
done

disk="$disk"G
ram="$ram"G

read -p "
Do you want to run instance with these settings?
  -name $name
  -disk $disk
  -cpus $cpus
  -ram  $ram

To get more info run script using flag -h.

Type y to approve: " approve

if [ "$approve" == "y" ]; then
  multipass launch lts --name $name --disk $disk --cpus $cpus --memory $ram --timeout 800
else
  exit 0;
fi