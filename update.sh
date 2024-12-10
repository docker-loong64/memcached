#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

./versions-loongson.sh "$@"
./apply-templates.sh "$@"
