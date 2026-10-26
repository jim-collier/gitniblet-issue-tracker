#!/usr/bin/env bash

##	Purpose: Move the shcl and gitniblet pins in cicd/container/Dockerfile to a
##		commit on each one's dev branch, the newest by default. The tests run
##		against those builds, never a release. A full run after a bump builds
##		the new image.
##	Usage: bump-pins.bash [shcl|gitniblet] [REV]
##		No name moves both to the newest dev. REV needs a name, and is a full
##		40-character commit.
##	Env:
##		NIT_PINS_FILE: another Dockerfile to edit, for the tests.
##	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
##	Licensed under The MIT License (MIT). Full text at:
##		https://mit-license.org/
##	SPDX-License-Identifier: MIT

set -Eeuo pipefail

here="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
pins="${NIT_PINS_FILE:-${here}/container/Dockerfile}"
fDie(){ printf 'bump-pins: %s\n' "${*}" >&2; exit 1; }

declare -A url=([shcl]="https://github.com/yottacore/shcl" [gitniblet]="https://github.com/yottacore/gitniblet")
declare -A arg=([shcl]="SHCL_REV" [gitniblet]="GITNIBLET_REV")

names=(shcl gitniblet); rev=""
if (($#)); then
	[[ -n "${url[${1}]:-}" ]]  ||  fDie "unknown name '${1}'; it's shcl or gitniblet"
	names=("${1}"); rev="${2:-}"
fi
[[ -f "${pins}" ]]  ||  fDie "no ${pins}"

for name in "${names[@]}"; do
	old="$(sed -n "s/^ARG ${arg[${name}]}=//p" "${pins}")"
	[[ "${old}" =~ ^[0-9a-f]{40}$ ]]  ||  fDie "${pins}: no full commit on 'ARG ${arg[${name}]}='"
	new="${rev}"
	if [[ -z "${new}" ]]; then
		new="$(git ls-remote "${url[${name}]}" refs/heads/dev | cut -f1)"
		[[ -n "${new}" ]]  ||  fDie "couldn't read dev from ${url[${name}]}"
	fi
	[[ "${new}" =~ ^[0-9a-f]{40}$ ]]  ||  fDie "need a full 40-character commit, got '${new}'"
	if [[ "${new}" == "${old}" ]]; then echo "${name}: already at ${new:0:8}"; continue; fi
	sed -i "s/^ARG ${arg[${name}]}=${old}\$/ARG ${arg[${name}]}=${new}/" "${pins}"
	echo "${name}: moved from ${old:0:8} to ${new:0:8}"
done


##	History:
##		- 20261025 JC: Created, after shclwrap's bump-shcl.bash.
