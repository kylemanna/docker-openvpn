# Install Latest Docker Service

Docker included with some distributions lags far behind upstream.  This guide aims to provide a quick and reliable way to install or update it.

It is recommended to use platforms that support systemd as future versions of this docker image may require systemd to help with some tasks:

* Fedora
* Debian 8.1+

## Debian / Ubuntu

### Step 1 — Set Up Docker

Docker is moving fast and Debian / Ubuntu's long term support (LTS) policy doesn't keep up. To work around this we'll install a PPA that will get us the latest version of Docker. For Debian Jessie users, just install docker.io from jessie-backports.

Ensure dependencies are installed:

    sudo apt-get update && sudo apt-get install -y apt-transport-https curl

Add the upstream Docker repository package signing key. The apt-key command uses elevated privileges via sudo, so a password prompt for the user's password may appear:

    curl -L https://get.docker.com/gpg | sudo apt-key add -

Add the upstream Docker repository to the system list:

    echo deb https://get.docker.io/ubuntu docker main | sudo tee /etc/apt/sources.list.d/docker.list

Update the package list and install the Docker package:

    sudo apt-get update && sudo apt-get install -y lxc-docker

Add your user to the `docker` group to enable communication with the Docker daemon as a normal user, where `$USER` is your username. Exit and log in again for the new group to take effect:

    sudo usermod -aG docker $USER

After **re-logging in** verify the group membership using the id command. The expected response should include docker like the following example:

    uid=1001(test0) gid=1001(test0) groups=1001(test0),27(sudo),999(docker)

### Step 2 — Test Docker

Run a Debian jessie docker container:

    docker run --rm -it debian:jessie bash -l

Once inside the container you'll see the `root@<container id>:/#` prompt signifying that the current shell is in a Docker container. To confirm that it's different from the host, check the version of Debian running in the container:

    cat /etc/issue.net

Expected result:

    Debian GNU/Linux 8
