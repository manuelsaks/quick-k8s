#!/bin/bash

name="rke2"
disk="18"
cpus="4"
ram="6"

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
    -ram Specify amount of RAM memory in GB. Recommended at least 6.

Default:
    ./script.sh -name rke2 -ram 6 -cpus 4 -disk 18
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

Type y to approve: " runApprove

if [ "$runApprove" == "y" ]; then
  multipass launch lts --name $name --disk $disk --cpus $cpus --memory $ram --timeout 800
  ipAddr=$(multipass list | grep $name | awk '{print $3}')
  dnsName="$name.multipass"
  dnsRecord="$ipAddr $dnsName"
  g=$(tput setaf 35) #green
  i=$(tput sitm) #italic
  b=$(tput bold) #bold
  n=$(tput sgr0) #normal
  multipass exec $name -- sudo mkdir -p /run/tmp
  multipass exec $name -- sudo service ufw stop
  multipass exec $name -- sudo ufw disable
  multipass exec $name -- sudo su -c 'curl -sfL https://get.rke2.io | sh -'
  multipass exec $name -- sudo systemctl enable rke2-server.service
  multipass exec $name -- sudo systemctl start rke2-server.service
  multipass exec $name -- sudo mkdir -p /home/ubuntu/.kube
  multipass exec $name -- sudo mkdir -p /root/.kube
  multipass exec $name -- sudo cp /etc/rancher/rke2/rke2.yaml /home/ubuntu/.kube/config
  multipass exec $name -- sudo cp /etc/rancher/rke2/rke2.yaml /root/.kube/config
  multipass exec $name -- sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
  multipass exec $name -- sudo wget -q -O /run/tmp/k9s_Linux_amd64.tar.gz https://github.com/derailed/k9s/releases/download/v0.27.2/k9s_Linux_amd64.tar.gz
  multipass exec $name -- sudo tar -xf /run/tmp/k9s_Linux_amd64.tar.gz --directory /run/tmp/
  multipass exec $name -- sudo mv /run/tmp/k9s /usr/bin
  multipass exec $name -- sudo snap install kubectl --classic
  multipass exec $name -- sudo snap install helm --classic
  multipass exec $name -- sudo wget -q -O /run/tmp/cert-manager-crd.yaml https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.crds.yaml
  multipass exec $name -- sudo helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
  multipass exec $name -- sudo helm repo add jetstack https://charts.jetstack.io
  multipass exec $name -- sudo helm repo update
  multipass exec $name -- sudo kubectl create namespace cert-manager
  multipass exec $name -- sudo kubectl apply -f /run/tmp/cert-manager-crd.yaml
  multipass exec $name -- sudo helm install cert-manager jetstack/cert-manager --namespace cert-manager
  sleep 30
  multipass exec $name -- sudo kubectl create namespace cattle-system
  sleep 30
  multipass exec $name -- sudo helm install rancher rancher-stable/rancher --namespace cattle-system --set hostname=$name.multipass  --set global.cattle.psp.enabled="false"
  echo "Isn't ready yet. Wait a few seconds..."
  multipass exec $name -- sudo su -c 'pass=""; while [ -z "$pass" ]; do sleep 1; pass=$(sudo cat /var/log/containers/* | grep "Bootstrap Password" | awk "{print $NF}"); done'
  sleep 5
  password=$(multipass exec $name -- sudo su -c 'kubectl get secret --namespace cattle-system bootstrap-secret -o go-template="{{.data.bootstrapPassword|base64decode}}"')
  printf "${b}\nDo you want to add DNS record now?${n}\n  ${i}Info: You can do it manually by adding ${g}$dnsRecord${n} ${i}to the /etc/hosts file.${n}\n"
  read -p "  Type y to approve: " hostsApprove
  if [ "$hostsApprove" == "y" ]; then
    if grep -Fq "${dnsName}" /etc/hosts; then
      printf "\n${b}The record ${dnsName} already exists!${n}\n"
      read -p "  Do you want to overwrite? `echo $'\n  Type y to approve: '`" overwriteApprove
      if [ "$overwriteApprove" == "y" ]; then
        printf "\n\n${b}Overwriting${n} /etc/hosts with the ${g}${dnsRecord}${n} record...\n\n"
        sudo sed -i "/${dnsName}/c ${dnsRecord}" /etc/hosts
      else
        printf "\n\n${b}Do it later${n} by adding ${g}$dnsRecord${n} to the /etc/hosts file.\n\n"
      fi
    else
      printf "\n\n${b}Adding:${n} ${g}${dnsRecord}${n} to the /etc/hosts file...\n\n"
      sudo sed -i "$ a $dnsRecord" /etc/hosts
    fi
  fi
  echo "----------------------------------------------------------"
  printf "\nCopy password below:\n\n"
  echo "${g}${b}$password${n}"
  printf "\n\nIf the DNS record exists you should be able to open ${b}https://$name.multipass/${n}\n\n"
  echo "----------------------------------------------------------"
else
  exit 0;
fi