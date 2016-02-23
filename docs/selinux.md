# For hosts that use SELinux

Try this [policy file](docker-openvpn.te)

Run these commands to compile and load it:

```
checkmodule -M -m -o docker-openvpn.mod docker-openvpn.te
semodule_package -o docker-openvpn.pp -m docker-openvpn.mod
sudo semodule -i docker-openvpn.pp
```

Also, some configurations don't allow containers to load kernel modules, so on the host run this:

```
sudo modprobe tun
```

So the container doesn't have to load the `tun` module.


# Still having issues?

In January 2016, Fedora based systems got an update that fixed an issue for labeling namespaced net objects under /proc
to fix, make sure that you have run `sudo dnf update` and you need to reboot to load the new policies
