#!/bin/bash
set -e

# NOT INTENDED TO BE USED AS A TEST "run.sh" DIRECTLY
# SEE OTHER "run-*-in-container.sh" SCRIPTS FOR USAGE

testDir="$1"
shift

image="$1"
shift
entrypoint="$1"
shift

# do some fancy footwork so that if testDir is /a/b/c, we mount /a/b and use c as the working directory (so relative symlinks work one level up)
thisDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
testDir="$(readlink -f "$testDir")"
testBase="$(basename "$testDir")"
hostMount="$(dirname "$testDir")"
containerMount="/tmp/test-dir"
workdir="$containerMount/$testBase"
# TODO should we be doing something fancy with $BASH_SOURCE instead so we can be arbitrarily deep and mount the top level always?

newImage="$("$thisDir/image-name.sh" librarytest/run-in-container "$image--$testBase")"
"$thisDir/docker-build.sh" "$hostMount" "$newImage" <<EOD
FROM $image
COPY dir $containerMount
WORKDIR $workdir
ENTRYPOINT ["$entrypoint"]
EOD

args=( --rm )

# there is strong potential for nokogiri+overlayfs failure
# see https://github.com/docker-library/ruby/issues/55
gemHome="$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$newImage" | awk -F '=' '$1 == "GEM_HOME" { print $2; exit }')"
if [ "$gemHome" ]; then
	# must be a Ruby image
	driver="$(docker info | awk -F ': ' '$1 == "Storage Driver" { print $2; exit }')"
	if [ "$driver" = 'overlay' ]; then
		# let's add a volume (_not_ a bind mount) on GEM_HOME to work around nokogiri+overlayfs issues
		args+=( -v "$gemHome" )
	fi
fi

exec docker run "${args[@]}" "$newImage" "$@"
