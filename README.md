# Dispos-A-VPN

It works on DigitalOcean and AWS. I haven't tested it anywhere else.

This was originally a fork of https://github.com/jpetazzo/dockvpn, but was redone to use Tinfoil Security's VPN script.

It adds the following features:

* A cloud-config file for CoreOS that launches this container and the config server.
* A script written in Python (using the CherryPy framework) to serve up the config file, with the ability to lock out said server when the user is done without touching SSH.

## Usage

### Requirements:

* Access to a service such as EC2, DigitalOcean etc that allows you to provide user data to instances and provides CoreOS images.
* The contents of `userdata.yml`.

### Steps (EC2):

1. Go to the CoreOS site and use the dropdown on the `Download CoreOS` button. Select EC2.
2. Look for the region you wish to run your VPN in.
3. Click one of the AMI IDs that correspond to your region.
4. Go through the instance creation process, but when asked for user data, paste the contents of `userdata.yml` into the box. You may also download `userdata.yml` and use the 'as file' option when asked for user data.
5. When asked for a security group, create a new one. Open TCP port 8080 and UDP port 1194.
6. When the instance has come up, wait. (5-10 minutes on t1. and t2. micros)  
7. Go to `https://<instance IP>:8080`.
8. Download the config, then point OpenVPN at it and connect.

### Steps (DigitalOcean):

1. Create a new droplet in a region that supports user data.
2. Choose CoreOS for the OS.
3. Paste the contents of `userdata.yml` into the user data box and create the droplet.
4. When the instance has come up, wait a couple of minutes and go to `https://<droplet IP>:8080`.
5. Download the config, then point OpenVPN at it and connect.
