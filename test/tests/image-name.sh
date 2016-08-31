#!/bin/bash
set -e

# usage: ./image-name.sh librarytest/something some/image:some-tag
# output: librarytest/something:some-image-some-tag

base="$1"; shift
tag="$1"; shift

echo "$base:$(echo "$tag" | sed 's![:/]!-!g')"
