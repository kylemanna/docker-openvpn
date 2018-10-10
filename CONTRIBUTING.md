# Contributing to docker-openvpn

Community contributions are welcome and help move the project along.  Please review this document before sending any pull requests.

Thanks!

## Bug Fixes

All bug fixes are welcome.  Please try to add a test if the bug is something that should have been fixed already.  Oops.

## Feature Additions

New features are welcome provided that the feature has a general audience and is reasonably simple.  The goal of the repository is to support a wide audience and be simple enough.

Please add new documentation in the `docs` folder for any new features.  Pull requests for missing documentation is welcome as well.  Keep the `README.md` focused on the most popular use case, details belong in the docs directory.

If you have a special feature, you're likely to try but it will likely be rejected if not too many people seem interested.

## Tests

In an effort to not repeat bugs (and break less popular features), unit tests are run on [Travis CI](https://travis-ci.org/kylemanna/docker-openvpn).  The goal of the tests are to be simple and to be placed in the `test/tests` directory where it will be automatically run.  Review existing tests for an example.

## Style

The style of the repo follows that of the Linux kernel, in particular:

* Pull requests should be rebased to small atomic commits so that the merged history is more coherent
* The subject of the commit should be in the form "`<subsystem>: <subject>`"
* More details in the body
* Match surrounding coding style (line wrapping, spaces, etc)

More details in the [SubmittingPatches](https://www.kernel.org/doc/html/latest/process/submitting-patches.html) document included with the Linux kernel.  In particular the following sections:

* `2) Describe your changes`
* `3) Separate your changes`
