#!/usr/bin/env bash
set -Eeuo pipefail

# NOT INTENDED TO BE USED AS A TEST "run.sh" DIRECTLY
# SEE OTHER "run-*-in-container.sh" SCRIPTS FOR USAGE

# arguments to docker
args=( --rm )
opts="$(getopt -o '+' --long 'docker-arg:' -- "$@")"
eval set -- "$opts"

while true; do
	flag="$1"
	shift
	case "$flag" in
		--docker-arg) args+=( "$1" ) && shift ;;
		--) break ;;
		*)
			{
				echo "error: unknown flag: $flag"
				#usage
			} >&2
			exit 1
			;;
	esac
done

testDir="$1"
shift

image="$1"
shift
entrypoint="$1"
shift

# do some fancy footwork so that if testDir is /a/b/c, we mount /a/b and use c as the working directory (so relative symlinks work one level up)
thisDir="$(readlink -f "$BASH_SOURCE")"
thisDir="$(dirname "$thisDir")"
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
EOD

# there is strong potential for nokogiri+overlayfs failure
# see https://github.com/docker-library/ruby/issues/55
gemHome="$(docker image inspect --format '{{- range .Config.Env -}}{{- println . -}}{{- end -}}' "$newImage" | awk -F '=' '$1 == "GEM_HOME" { print $2; exit }')"
if [ -n "$gemHome" ]; then
	# must be a Ruby image
	driver="$(docker info --format '{{ .Driver }}' 2>/dev/null)"
	if [ "$driver" = 'overlay' ]; then
		# let's add a volume (_not_ a bind mount) on GEM_HOME to work around nokogiri+overlayfs issues
		args+=( -v "$gemHome" )
	fi
fi

args+=( --entrypoint "$entrypoint" )

# we can't use "exec" here because Windows needs to override "docker" with a function that sets "MSYS_NO_PATHCONV" (see "test/run.sh" for where that's defined)
if ! docker run "${args[@]}" "$newImage" "$@"; then
	exit 1
fi
exit 0
