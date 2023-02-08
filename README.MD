## Info
The script creates Ubuntu LTS machine using Multipass and installs RKE2 with Rancher on a single virtual machine.

## Windows
1. Make sure that you have running and correctly configured Hyper-V.
1. Install Multipass and choose Hyper-V as provider (download: multipass.run/install).
1. To get help run:
  ```
  powershell windows\hyperv_run.ps1 -h 
  ```
1. To try it out run:
  ```
  powershell windows\hyperv_run.ps1
  ```
1. It takes about 5-10 minutes.