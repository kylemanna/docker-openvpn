# Tests

Philosophy is to not re-invent the wheel while allowing users to quickly test repository specific tests.

Example invocation from top-level of repository:

    docker build -t kylemanna/openvpn .
    test/run.sh kylemanna/openvpn
    # Be sure to pull kylemanna/openvpn:latest after you're done testing

More details: https://github.com/docker-library/official-images/tree/master/test

## Continuous Integration

The set of scripts defined by `config.sh` are run every time a pull request or push to the repository is made.

## Maintenance

Periodically these scripts may need to be synchronized with their upsteam source.  Would be nice to be able to just use them from upstream if it such a feature is added later to avoid having to copy them in place.
