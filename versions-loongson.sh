#!/usr/bin/env bash
set -Eeuo pipefail

minVersion="1.6.1"
excludeVersions=("1.6.11")
#alpine="$(
#	bashbrew cat --format '{{ .TagEntry.Tags | join "\n" }}' https://github.com/docker-library/official-images/raw/HEAD/library/alpine:latest \
#		| grep -E '^[0-9]+[.][0-9]+$'
#)"
#[ "$(wc -l <<<"$alpine")" = 1 ]
alpine="3.19"
export alpine

#debian="$(
#	bashbrew cat --format '{{ .TagEntry.Tags | join "\n" }}' https://github.com/docker-library/official-images/raw/HEAD/library/debian:latest \
#		| grep -vE '^latest$|[0-9.-]' \
#		| head -1
#)"
#[ "$(wc -l <<<"$debian")" = 1 ]
debian="sid"
export debian

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

#versions=( "$@" )
#if [ ${#versions[@]} -eq 0 ]; then
#	versions=( */ )
#	json='{}'
#else
#	json="$(< versions.json)"
#fi
#versions=( "${versions[@]%/}" )

versions="$(
	git ls-remote --tags 'https://github.com/memcached/memcached.git' \
		| cut -d/ -f3- \
		| cut -d^ -f1 \
		| grep -E '^[0-9]+' \
		| grep -vE -- '-(beta|rc)' \
		| sort -urV
)"

#read -r -a versions <<< $versions

versions=($versions)

json='{}'
for version in "${versions[@]}"; do
	export version

        if printf '%s\n' "${excludeVersions[@]}" | grep -qx "$version"; then
            # skip excludeVersions
            continue;
        fi
	#versionPossibles="$(grep <<<"$possibles" -E "^$version([.-]|\$)")"

	fullVersion=
	sha1=
	url="https://memcached.org/files/memcached-$version.tar.gz"
	if sha1="$(curl -fsSL "$url.sha1")" && [ -n "$sha1" ]; then
		sha1="${sha1%% *}"
		fullVersion="$version"
	else
		break
	fi
	if [ -z "$fullVersion" ]; then
		echo >&2 "error: could not determine latest release for $version"
		exit 1
	fi
	[ -n "$sha1" ]
	[ -n "$url" ]

	echo "$version: $fullVersion"

	export fullVersion sha1 url
	json="$(jq <<<"$json" -c '
		.[env.version] = {
			version: env.fullVersion,
			url: env.url,
			sha1: env.sha1,
			alpine: { version: env.alpine },
			debian: { version: env.debian },
		}
	')"

        if [ $version == $minVersion ]; then
            break
        fi
done

jq <<<"$json" . > versions.json
