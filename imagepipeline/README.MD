# Using Packer & Ansible inside AWS CodeBuild

##### Have the builspec install the following components:
* [ansible](https://www.ansible.com/)
* [psrp](https://pypi.org/project/pypsrp)
  * [pywinrm](https://pypi.org/project/pywinrm) is another option, but we had difficulty getting that python library to successfully execute powershell commands on the target EC2 instance when using the AWS provided images.  pywinrm did seem to work if we ran CodeBuild in a home-grown Alpine Linux based image or if we ran Packer & Ansible from Amazon Linux 2 based EC2 instances outside of CodeBuild.
* [packer](https://www.packer.io/)

##### Use an AWS provided image to run CodeBuild
In my example, I used [aws/codebuild/amazonlinux2-x86_64-standard:3.0](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html).

##### Packer configs
* Do not include any secrets or passwords as Packer & Ansible work well to use the default Administrator credentials created when AWS starts the instance
* Ensure that the Security Group rules & NACLs allow the CodeBuild running container to communicate with the target ephemeral EC2 instance over the necessary ports (i.e. WinRM over HTTPS is 5986).
* Configure Packer to communicate with the target instance using WinRM w/ SSL over Port 5986.
  * You also need to ignore SSL certificate errors since the script uses a self-signed certificate that likely doesn't match the hostname/IP.
  * Packer should also authenticate to the EC2 instance using NTLM so that Basic authentication does not need to be enabled on the EC2 instance (per CIS hardening recommendations)
* If WinRM is not correctly configured on the Packer source AMI, a [user data script](./ec2-userdata.ps1) should be used to configure it at startup in order for Packer & Ansible to connect to the WinRM service remotely.
* Ansible should be run from Packer using the [Ansible provisioner](#ansible-configs)

##### Ansible configs
* Ansible should be run without an inventory file in order to just run playbooks against a target
* Ansible should be configured to use the psrp library to connect to the EC2 instance
* Similar to Packer, Ansible should also authenticate using NTLM and ignore certificate issues
* By default Ansible will use the default Administrator credentials created when AWS starts the instance so no need to specify credentials

##### Powershell script to configure WinRM listener
* Some configs are managed by GPO so the GPO policy needs to be updated and not the configuration directly otherwise the setting gets reverted when the GPO is re-applied.
* The [user data script](./ec2-userdata.ps1) is documented in line, but in short it:
  * Installs a Powershell cmdlet to manage GPO settings
  * Creates & configures a new WinRM listener on port 5986 using HTTPS allowing authentication to be negotiated (Kerberos or NTLM)
    * It is not listening on port 5985 using HTTP and it is not configured to allow Basic authentication
  * Configures UAC to allow privilege elevation in remote shells via GPO
  * Restart the WinRM Service & configures it to autostart on boot
  * Create firewall rule via GPO to open the necessary port (5986)
    * The script currently opens that port for all firewall profiles (Domain, Private & Public).  Domain probably isn't necessary in AWS where there isn't a Domain. Private should be sufficient for communicating from CodeBuild containers to the EC2 instance. But Public is needed if running Packer & Ansible locally for troubleshooting.
