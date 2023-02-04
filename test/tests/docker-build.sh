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

tmp="$(mktemp -d "${TMPDIR:-/tmp}/docker-library-test-build-XXXXXXXXXX")"
trap "rm -rf '$tmp'" EXIT

cat > "$tmp/Dockerfile"

from="$(awk -F '[ \t]+' 'toupper($1) == "FROM" { print $2; exit }' "$tmp/Dockerfile")"
if ! docker inspect "$from" &> /dev/null; then
	docker pull "$from" > /dev/null
fi

cp -RL "$dir" "$tmp/dir"

command docker build -t "$imageTag" "$tmp" > /dev/null
