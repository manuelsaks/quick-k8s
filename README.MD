## Info
The script creates Ubuntu LTS machine using Multipass and installs RKE2 with Rancher on a single virtual machine.

It takes about 5-10 minutes.

## Linux
1. Install Multipass and make sure it's working _(download: multipass.run/install)_.
2. To get help run:
  ```
  bash linux/run.sh -h 
  ```
3. To try it out run:
  ```
  bash linux/run.sh
  ```

## Windows
1. Make sure that you have running and correctly configured Hyper-V.
2. Install Multipass and choose Hyper-V as provider _(download: multipass.run/install)_.
3. To get help run:
  ```
  powershell windows\hyperv_run.ps1 -h
  ```
4. To try it out run:
  ```
  powershell windows\hyperv_run.ps1
  ```

## Removal
- To delete a specific instance:
  ```
  multipass delete <instance-name>  --purge
  ```

- To permanently delete all instances:
  ```
  multipass delete --all --purge
  ```