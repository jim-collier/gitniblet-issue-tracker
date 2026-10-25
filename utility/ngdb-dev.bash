#!/usr/bin/env bash

##	Purpose:
##		Run ngdb against the database source/config.shcl describes. ngdb reads a
##		registry record with absolute paths, under <registry>/<name>/config.shcl,
##		and writes last_opened back into it. So this resolves config.shcl into such
##		a record beside the SQLite view, rather than letting ngdb touch the tracked
##		file, then runs ngdb with that registry.
##		- A relative path in config.shcl is relative to that file. ${HOME} is the
##		  one variable expanded.
##		- The database name goes in after any verb that takes one, so
##		  "ngdb-dev.bash create issue title=x" is "ngdb create <name> issue title=x".
##		- sync is refused, since it commits and pushes the log on whatever branch
##		  the dev repo has checked out.
##	Syntax:
##		ngdb-dev.bash [--config-file=PATH] [--print] <ngdb verb> [args...]
##		  --config-file  another config.shcl, such as a test run's copy
##		  --print        print the resolved paths and stop
##	Env:
##		NGDB_BIN: the ngdb binary, default the one on PATH.
##	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
##	Licensed under the GNU Affero General Public License v3.0.
##	SPDX-License-Identifier: AGPL-3.0-only
##	History: At bottom of script.

set -Eeuo pipefail

meDir="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cfg="${meDir}/../source/config.shcl"
ngdbBin="${NGDB_BIN:-ngdb}"
doPrint=0

while (($#)); do case "${1}" in
	--config-file=*)  cfg="${1#*=}"; shift ;;
	--config-file)    cfg="${2:-}"; shift 2 ;;
	--print)          doPrint=1; shift ;;
	*)                break ;;
esac; done

fDie(){ printf 'ngdb-dev: %s\n' "${1}" >&2; exit 1; }

[[ -f "${cfg}" ]]  ||  fDie "no config file at ${cfg}"
command -v shcl > /dev/null  ||  fDie "shcl isn't on PATH"
cfgDir="$(cd -P -- "$(dirname -- "${cfg}")" && pwd -P)"
cfg="${cfgDir}/$(basename -- "${cfg}")"

fGet(){
	local val
	val="$(shcl get --string "${cfg}" "${1}" 2> /dev/null)"  ||  fDie "${cfg}: no ${1}"
	[[ -n "${val}" ]]  ||  fDie "${cfg}: ${1} is empty"
	printf '%s' "${val}"
}

## Plain text replacement, never eval, so a path can't run anything.
fResolve(){
	local p="${1//\$\{HOME\}/${HOME}}"
	[[ "${p}" == /* ]]  ||  p="${cfgDir}/${p}"
	realpath -m -- "${p}"
}

name="$(fGet name)"
[[ "${name}" =~ ^[A-Za-z0-9._-]+$ ]]  ||  fDie "${cfg}: name \"${name}\" isn't a plain file name"
ddlPath="$(fResolve "$(fGet ddl_path)")"
logDir="$(fResolve "$(fGet log_dir)")"
sqlitePath="$(fResolve "$(fGet sqlite_path)")"
registry="$(dirname -- "${sqlitePath}")/registry"
record="${registry}/${name}/config.shcl"

if ((doPrint)); then
	printf 'name:     %s\nconfig:   %s\nddl:      %s\ntx-log:   %s\nsqlite:   %s\nregistry: %s\n' \
		"${name}" "${cfg}" "${ddlPath}" "${logDir}" "${sqlitePath}" "${record}"
	exit 0
fi

[[ -f "${ddlPath}" ]]  ||  fDie "no DDL at ${ddlPath}"
mkdir -p -- "${logDir}" "$(dirname -- "${record}")"
## Edits only these keys, so ngdb's last_opened survives.
out="$(shcl set --write --no-banner \
	--set-literal "name=${name}" \
	--set-literal "ddl_path=${ddlPath}" \
	--set-literal "log_dir=${logDir}" \
	--set-literal "sqlite_path=${sqlitePath}" \
	"${record}" 2>&1 < /dev/null)"  ||  fDie "couldn't write ${record}: ${out}"

verb="${1:-}"
case "${verb}" in
	sync)  fDie "sync is refused here; it commits and pushes the log on the dev repo's checked-out branch" ;;
	build|replay|gc|create|get|update|setnull|markdelete|delete|query|comment|comments|attachuri|attachfile|attachments|--rename-table|--rename-field|--tui|--serve)
		shift; set -- "${verb}" "${name}" "${@}" ;;
esac

exec "${ngdbBin}" --config "${registry}" "${@}"


##	History:
##		- 20261025 JC: Created.
