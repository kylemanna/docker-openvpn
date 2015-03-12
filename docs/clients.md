# Advanced client management

## Client configuration mode

The `ovpn_getclient` can produce two different format of configuration.

1. combined: All needed configuration and cryptographic material is in one file (Use "combined-save" to write the configuration file in the same path as the separated parameter does).
2. separated: Separated files.

Some client software might be picky about which configuration format it accepts.

## Batch mode

If you have more than a few clients, you will want to generate and update your client configuration in batch. For this task the script `ovpn_getclient_all` was written, which writes out the configuration for each client to a separate directory called `clients/$cn`.

Execute the following to generate the configuration for all clients:

    docker run --rm -t -i -v /tmp/openvpn:/etc/openvpn kylemanna/openvpn ovpn_getclient_all

After doing so, you will find the following files in each of the `$cn` directories:

    ca.crt
    dh.pem
    $cn-combined.ovpn # Combined configuration file format, you your client recognices this file then only this file is needed.
    $cn.ovpn          # Separated configuration. This configuration file requires the other files ca.crt dh.pem $cn.crt $cn.key ta.key
    $cn.crt
    $cn.key
    ta.key
