#!/bin/bash
set -e

# wrapper around "docker build" that creates a temporary directory and copies files into it first so that arbitrary host directories can be copied into containers without bind mounts, but accepts a Dockerfile on stdin

# usage: ./docker-build.sh some-host-directory some-new-image:some-tag <<EOD
#        FROM ...
#        COPY dir/... /.../
#        EOD
#    ie: ./docker-build.sh .../hylang-hello-world librarytest/hylang <<EOD
#        FROM hylang
#        COPY dir/container.hy /dir/
#        CMD ["hy", "/dir/container.hy"]
#        EOD

dir="$1"; shift
[ -d "$dir" ]

imageTag="$1"; shift

tmp="$(mktemp -t -d docker-library-test-build-XXXXXXXXXX)"
trap "rm -rf '$tmp'" EXIT

cat > "$tmp/Dockerfile"

from="$(awk -F '[ \t]+' 'toupper($1) == "FROM" { print $2; exit }' "$tmp/Dockerfile")"
onbuilds="$(docker inspect -f '{{len .Config.OnBuild}}' "$from")"
if [ "$onbuilds" -gt 0 ]; then
	# crap, the image we want to build has some ONBUILD instructions
	# those are kind of going to ruin our day
	# let's do some hacks to strip those bad boys out in a new fake layer
	"$(dirname "$(readlink -f "$BASH_SOURCE")")/remove-onbuild.sh" "$from" "$imageTag"
	awk -F '[ \t]+' 'toupper($1) == "FROM" { $2 = "'"$imageTag"'" } { print }' "$tmp/Dockerfile" > "$tmp/Dockerfile.new"
	mv "$tmp/Dockerfile.new" "$tmp/Dockerfile"
fi

cp -RL "$dir" "$tmp/dir"

docker build -t "$imageTag" "$tmp" > /dev/null
