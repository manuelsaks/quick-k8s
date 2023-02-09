

param(
    [switch]$h,
    [string]$name = "rke2",
    [string]$disk = "18",
    [string]$cpus = "4",
    [string]$ram = "8"
)

$disk = $disk + "G"
$ram = $ram + "G"

if ($h) {
    Write-Host @"
    `nInfo:
      You have to install Multipass that uses Hyper-V. Virtualbox is not supported in this script!
    `nParameters:
      -name  Give a name for your instance.
      -disk  Specify disk size in GB. Recommended at least 18.
      -cpus  Number of CPU cores. Recommended at least 4.
      -ram   Specify amount of RAM memory in GB. Recommended at least 8.

    `nDefault:
      powershell run.ps1 -name rke2 -ram 8 -cpus 4 -disk 18
"@
    return
}

$approve=Read-Host -Prompt @"
`nDo you want to run instance with these settings?
    -name   $name
    -disk   $disk
    -cpus   $cpus
    -ram    $ram

`nTo get more info run script using flag -h.
`nType y to approve
"@

if ($approve -eq "y") {
    Write-Output "`n"
    $check = "pass=''; while [ -z `"`$pass`" ]; do sleep 1; pass=`$(sudo cat /var/log/containers/* | grep 'Bootstrap Password' | awk '{print `$NF}'); done"
    $encodedCheck = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($check))
    $ErrorActionPreference = 'SilentlyContinue'
    multipass launch lts --name $name --disk $disk --cpus $cpus --memory $ram --timeout 800
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
    multipass exec $name -- sudo su -c "echo $encodedCheck | base64 --decode > /run/tmp/check.sh"
    multipass exec $name -- sudo chmod +x /run/tmp/check.sh
    Start-Sleep -Seconds 30
    multipass exec $name -- sudo kubectl create namespace cattle-system
    Start-Sleep -Seconds 30
    multipass exec $name -- sudo helm install rancher rancher-stable/rancher --namespace cattle-system --set hostname=$name.mshome.net
    Write-Output "Isn't ready yet. Wait a few seconds..."
    multipass exec $name -- sudo bash /run/tmp/check.sh
    Start-Sleep -Seconds 5
    Write-Output "----------------------------------------------------------"
    Write-Output "`n"
    Write-Output "Done! Copy password below:"
    Write-Output "`n"
    multipass exec $name -- sudo su -c "kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}'"
    Write-Output "`n"
    Write-Output "and visit https://$name.mshome.net"
    Write-Output "`n"
    Write-Output "----------------------------------------------------------"
}