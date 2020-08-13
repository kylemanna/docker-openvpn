#!/bin/bash
set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

self="$(basename "$0")"

usage() {
	cat <<EOUSAGE

usage: $self [-t test ...] image:tag [...]
   ie: $self debian:wheezy
       $self -t utc python:3
       $self -t utc python:3 -t python-hy

This script processes the specified Docker images to test their running
environments.
EOUSAGE
}

# arg handling
opts="$(getopt -o 'ht:c:?' --long 'dry-run,help,test:,config:' -- "$@" || { usage >&2 && false; })"
eval set -- "$opts"

declare -A argTests=()
declare -a configs=()
dryRun=
while true; do
	flag=$1
	shift
	case "$flag" in
		--dry-run) dryRun=1 ;;
		--help|-h|'-?') usage && exit 0 ;;
		--test|-t) argTests["$1"]=1 && shift ;;
		--config|-c) configs+=("$(readlink -f "$1")") && shift ;;
		--) break ;;
		*)
			{
				echo "error: unknown flag: $flag"
				usage
			} >&2
			exit 1
			;;
	esac
done

if [ $# -eq 0 ]; then
	usage >&2
	exit 1
fi

# declare configuration variables
declare -a globalTests=()
declare -A testAlias=()
declare -A imageTests=()
declare -A globalExcludeTests=()
declare -A explicitTests=()

# if there are no user-specified configs, use the default config
if [ ${#configs} -eq 0 ]; then
	configs+=("$dir/config.sh")
fi

# load the configs
declare -A testPaths=()
for conf in "${configs[@]}"; do
	. "$conf"

	# Determine the full path to any newly-declared tests
	confDir="$(dirname "$conf")"

	for testName in ${globalTests[@]} ${imageTests[@]}; do
		[ "${testPaths[$testName]}" ] && continue

		if [ -d "$confDir/tests/$testName" ]; then
			# Test directory found relative to the conf file
			testPaths[$testName]="$confDir/tests/$testName"
		elif [ -d "$dir/tests/$testName" ]; then
			# Test directory found in the main tests/ directory
			testPaths[$testName]="$dir/tests/$testName"
		fi
	done
done

didFail=
for dockerImage in "$@"; do
	echo "testing $dockerImage"
	
	if ! docker inspect "$dockerImage" &> /dev/null; then
		echo $'\timage does not exist!'
		didFail=1
		continue
	fi
	
	repo="${dockerImage%:*}"
	tagVar="${dockerImage#*:}"
	#version="${tagVar%-*}"
	variant="${tagVar##*-}"
	
	testRepo=$repo
	[ -z "${testAlias[$repo]}" ] || testRepo="${testAlias[$repo]}"
	
	explicitVariant=
	if [ \
		"${explicitTests[:$variant]}" \
		-o "${explicitTests[$repo:$variant]}" \
		-o "${explicitTests[$testRepo:$variant]}" \
	]; then
		explicitVariant=1
	fi
	
	testCandidates=()
	if [ -z "$explicitVariant" ]; then
		testCandidates+=( "${globalTests[@]}" )
	fi
	testCandidates+=(
		${imageTests[:$variant]}
	)
	if [ -z "$explicitVariant" ]; then
		testCandidates+=(
			${imageTests[$testRepo]}
		)
	fi
	testCandidates+=(
		${imageTests[$testRepo:$variant]}
	)
	if [ "$testRepo" != "$repo" ]; then
		if [ -z "$explicitVariant" ]; then
			testCandidates+=(
				${imageTests[$repo]}
			)
		fi
		testCandidates+=(
			${imageTests[$repo:$variant]}
		)
	fi
	
	tests=()
	for t in "${testCandidates[@]}"; do
		if [ ${#argTests[@]} -gt 0 -a -z "${argTests[$t]}" ]; then
			# skipping due to -t
			continue
		fi
		
		if [ \
			! -z "${globalExcludeTests[${testRepo}_$t]}" \
			-o ! -z "${globalExcludeTests[${testRepo}:${variant}_$t]}" \
			-o ! -z "${globalExcludeTests[:${variant}_$t]}" \
			-o ! -z "${globalExcludeTests[${repo}_$t]}" \
			-o ! -z "${globalExcludeTests[${repo}:${variant}_$t]}" \
			-o ! -z "${globalExcludeTests[:${variant}_$t]}" \
		]; then
			# skipping due to exclude
			continue
		fi
		
		tests+=( "$t" )
	done
	
	currentTest=0
	totalTest="${#tests[@]}"
	for t in "${tests[@]}"; do
		(( currentTest+=1 ))
		echo -ne "\t'$t' [$currentTest/$totalTest]..."
		
		# run test against dockerImage here
		# find the script for the test
		scriptDir="${testPaths[$t]}"
		if [ -d "$scriptDir" ]; then
			script="$scriptDir/run.sh"
			if [ -x "$script" -a ! -d "$script" ]; then
				# TODO dryRun logic
				if output="$("$script" $dockerImage)"; then
					if [ -f "$scriptDir/expected-std-out.txt" ] && ! d="$(echo "$output" | diff -u "$scriptDir/expected-std-out.txt" - 2>/dev/null)"; then
						echo 'failed; unexpected output:'
						echo "$d"
						didFail=1
					else
						echo 'passed'
					fi
				else
					echo 'failed'
					didFail=1
				fi
			else
				echo "skipping"
				echo >&2 "error: $script missing, not executable or is a directory"
				didFail=1
				continue
			fi
		else
			echo "skipping"
			echo >&2 "error: unable to locate test '$t'"
			didFail=1
			continue
		fi
	done
done

if [ "$didFail" ]; then
	exit 1
fi
