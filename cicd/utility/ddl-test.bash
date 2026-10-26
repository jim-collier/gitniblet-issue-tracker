#!/usr/bin/env bash
#  shellcheck source-path=SCRIPTDIR  ## Sourced helpers resolve from this file, not the caller's cwd.
#  shellcheck enable=require-variable-braces  ## Every expansion braced: "${var}", not "$var".

##	Purpose:
##		Regression tests for the database definition: source/config.shcl,
##		source/ddl.shcl and its named queries, and the tracked tx-log. Every write
##		goes to a copy of the database in a temp folder, never the tracked log.
##		Prints one line per test, "PASS|FAIL|SKIP <id> <name>", and exits 1 when
##		any test fails.
##	Syntax:
##		ddl-test.bash [--list] [area...]
##		  area: config, ddl, log. None means all of them.
##		  --list  print the test IDs and names, and run nothing.
##	Env:
##		GITNIBLET_BIN: the gitniblet binary, default the one on PATH.
##		NIT_RUN_DIR: the cicd run's folder. Without it this makes its own.
##	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
##	Licensed under the GNU Affero General Public License v3.0.
##	SPDX-License-Identifier: AGPL-3.0-only
##	History: At bottom of script.

set -Eeuo pipefail

meDir="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repoDir="$(cd -P -- "${meDir}/../.." && pwd -P)"
srcDir="${repoDir}/source"
gitnibletDev="${repoDir}/utility/gitniblet-dev.bash"
gitnibletBin="${GITNIBLET_BIN:-gitniblet}"

# shellcheck source=include/temp-run.bash
source "${meDir}/include/temp-run.bash"

## ID, area, name, function. IDs never change once given.
declare -a tests=(
	"dedqv|config|config.shcl resolves to the documented layout|fT_ConfigLayout"
	"dedqw|config|config.shcl loads clean as shcl 3|fT_ConfigShcl"
	"dedqx|ddl|DDL loads in gitniblet with no warnings|fT_DdlGitniblet"
	"dedqy|ddl|DDL has no shcl 3 errors beyond its 2.x seed rows|fT_DdlShcl"
	"dedqz|ddl|named queries load clean as shcl 3|fT_QueriesShcl"
	"dedr0|ddl|git sync is off in the DDL|fT_SyncOff"
	"dedr1|log|seed rows replay into 5 lookup groups and 27 values|fT_Seeds"
	"dedr2|log|an issue with lookup values creates and reads back|fT_Create"
	"dedr3|log|a value outside its lookup group is refused|fT_LookupRefused"
	"dedr4|log|an issue with no title is refused|fT_TitleRefused"
	"dedr5|log|child issue, decision, link, comment and audit trail|fT_Children"
	"dedr6|log|a fresh replay rebuilds the same view|fT_Replay"
	"dedr7|log|every named query runs|fT_Queries"
	"dedr8|log|the tracked tx-log replays clean|fT_TrackedLog"
	"dedr9|config|the dev wrapper refuses sync|fT_SyncRefused"
	"dedra|log|date_created survives a replay into a new view|fT_DateCreated"
)

doList=0
declare -a areas=()
while (($#)); do case "${1}" in
	--list)  doList=1; shift ;;
	config|ddl|log)  areas+=("${1}"); shift ;;
	*)  printf 'ddl-test: unknown option or area: %s\n' "${1}" >&2; exit 2 ;;
esac; done

fWanted(){
	((${#areas[@]}))  ||  return 0
	local a; for a in "${areas[@]}"; do [[ "${a}" == "${1}" ]]  &&  return 0; done
	return 1
}

if ((doList)); then
	for t in "${tests[@]}"; do IFS='|' read -r id area name _ <<< "${t}"; fWanted "${area}"  &&  printf '%s %-6s %s\n' "${id}" "${area}" "${name}"; done
	exit 0
fi

ownRun=""
if [[ -n "${NIT_RUN_DIR:-}" && -d "${NIT_RUN_DIR}" ]]; then work="$(mktemp -d "${NIT_RUN_DIR}/ddl-test.XXXXXX")"
else ownRun="$(fTempRun_Make)"; work="${ownRun}"; fi
fCleanup(){ if [[ -n "${ownRun}" && -d "${ownRun}" ]]; then fSafeRm "${ownRun}" > /dev/null  ||  true; fi; }
trap fCleanup EXIT

## Writes are stamped with these, so the test log never names this box.
export GITNIBLET_USER="tester" GITNIBLET_HOST="testbox"

## A database of its own under the work folder: <dir>/config.shcl, with the
## log copied from LOGSRC when given.
fDb_Make(){
	local dir="${work}/${1}" logSrc="${2:-}"
	mkdir -p -- "${dir}/log"
	[[ -z "${logSrc}" ]]  ||  cp -a -- "${logSrc}/." "${dir}/log/"
	printf 'name:        "issue-tracker_test"\nddl_path:    "%s"\nlog_dir:     "log"\nsqlite_path: "view/local.sqlite"\n' "${srcDir}/ddl.shcl" > "${dir}/config.shcl"
	printf '%s\n' "${dir}/config.shcl"
}
fGitniblet(){ local cfg="${1}"; shift; GITNIBLET_BIN="${gitnibletBin}" "${gitnibletDev}" --config-file="${cfg}" "${@}"; }

## Tests print why on stdout and return non-zero to fail, or 3 to skip.

fT_ConfigLayout(){
	local out want
	out="$("${gitnibletDev}" --print)"
	for want in \
		"ddl:      ${srcDir}/ddl.shcl" \
		"tx-log:   ${repoDir}/gitniblet/issue-tracker_test" \
		"sqlite:   ${HOME}/.cache/gitniblet/issue-tracker_test/local.sqlite"
	do grep -qxF -- "${want}" <<< "${out}"  ||  { printf 'missing: %s\n%s\n' "${want}" "${out}"; return 1; }; done
}

fT_ConfigShcl(){ shcl check "${srcDir}/config.shcl" > "${work}/out.txt" 2>&1  ||  { cat "${work}/out.txt"; return 1; }; }

fT_DdlGitniblet(){
	"${gitnibletBin}" ddl "${srcDir}/ddl.shcl" > "${work}/out.txt" 2>&1  ||  { cat "${work}/out.txt"; return 1; }
	if grep -q 'warning:' "${work}/out.txt"; then grep 'warning:' "${work}/out.txt"; return 1; fi
}

## gitniblet's shcl 2.x reader takes a seed row's fields bare and comma separated,
## which shcl 3 refuses, so only those lines may fail. Anything else fails here.
fT_DdlShcl(){
	local line num code bad=0 known=0 text
	shcl check "${srcDir}/ddl.shcl" > "${work}/out.txt" 2>&1  ||  true
	while IFS= read -r line; do
		[[ "${line}" =~ ^line\ ([0-9]+):\ (Error|Warning):\ ([A-Z][0-9]{3})\  ]]  ||  continue
		num="${BASH_REMATCH[1]}"; code="${BASH_REMATCH[3]}"
		text="$(sed -n "${num}p" "${srcDir}/ddl.shcl")"
		if [[ "${code}" =~ ^E02[56]$ && "${text}" =~ ^[[:space:]]*row:\  ]]; then ((++known))
		else printf '%s\n' "${line}"; bad=1; fi
	done < "${work}/out.txt"
	((! bad))  ||  return 1
	printf '%s seed rows left to gitniblet until it reads shcl 3\n' "${known}"
}

fT_QueriesShcl(){ shcl check "${srcDir}/ddl.queries.shcl" > "${work}/out.txt" 2>&1  ||  { cat "${work}/out.txt"; return 1; }; }

fT_SyncOff(){
	local val; val="$(shcl get --string "${srcDir}/ddl.shcl" tunables.git_sync_frequency 2> /dev/null  ||  true)"
	[[ "${val}" == "0" ]]  ||  { printf 'tunables.git_sync_frequency is "%s"\n' "${val}"; return 1; }
}

## The log tests share one database, made here, in order.
dbMain=""
fT_Seeds(){
	local out
	dbMain="$(fDb_Make main)"
	fGitniblet "${dbMain}" replay > /dev/null
	out="$(fGitniblet "${dbMain}" query "SELECT count(*) FROM lookups WHERE idx BETWEEN 1 AND 5")"
	[[ "${out##*$'\n'}" == "5" ]]  ||  { printf 'lookup groups: %s\n' "${out}"; return 1; }
	out="$(fGitniblet "${dbMain}" query "SELECT count(*) FROM lookup_values WHERE lookups_idx BETWEEN 1 AND 5")"
	[[ "${out##*$'\n'}" == "27" ]]  ||  { printf 'lookup values: %s\n' "${out}"; return 1; }
}

parentId=""
fT_Create(){
	[[ -n "${dbMain}" ]]  ||  { echo "needs the seeds test"; return 3; }
	local out
	parentId="$(fGitniblet "${dbMain}" create issue ref=2026102508172800 title="Parent item" type=4 status=19 priority=31 opened="2026-10-25 08:17" | tail -1)"
	[[ -n "${parentId}" ]]  ||  return 1
	## One column, since gitniblet prints columns in name order, not as selected.
	out="$(fGitniblet "${dbMain}" query "SELECT ref || ' ' || type || ' ' || status || ' ' || priority AS v FROM issue WHERE id = id('${parentId}')")"
	[[ "${out##*$'\n'}" == "2026102508172800 4 19 31" ]]  ||  { printf 'read back: %s\n' "${out}"; return 1; }
}

## A refusal has to be gitniblet's own message, so a crash doesn't pass.
fRefused(){
	local want="${1}"; shift
	if fGitniblet "${dbMain}" "${@}" > "${work}/out.txt" 2>&1; then printf 'accepted: %s\n' "$(cat "${work}/out.txt")"; return 1; fi
	grep -qF -- "${want}" "${work}/out.txt"  ||  { cat "${work}/out.txt"; return 1; }
}

fT_LookupRefused(){
	[[ -n "${dbMain}" ]]  ||  { echo "needs the seeds test"; return 3; }
	fRefused "isn't a value in lookup group 2" create issue ref=2026102508190000 title="Bad status" status=1
}

fT_TitleRefused(){
	[[ -n "${dbMain}" ]]  ||  { echo "needs the seeds test"; return 3; }
	fRefused "title can't be null" create issue ref=2026102508200000 status=19
}

fT_Children(){
	[[ -n "${parentId}" ]]  ||  { echo "needs the create test"; return 3; }
	local child out
	child="$(fGitniblet "${dbMain}" create issue ref=2026102508180400 title="Child item" type=2 status=18 priority=32 parent_issue="${parentId}" | tail -1)"
	fGitniblet "${dbMain}" create decision issue="${child}" text="Lists stay 2.x until gitniblet reads shcl 3" > /dev/null
	fGitniblet "${dbMain}" create issue_link issue="${child}" other_issue="${parentId}" kind=50 > /dev/null
	fGitniblet "${dbMain}" comment issue "${child}" "Started" > /dev/null
	fGitniblet "${dbMain}" update issue "${child}" status=20 > /dev/null
	out="$(fGitniblet "${dbMain}" query "SELECT (SELECT count(*) FROM issue WHERE parent_issue = id('${parentId}')) || ' ' || (SELECT count(*) FROM decision WHERE issue = id('${child}')) || ' ' || (SELECT count(*) FROM issue_link WHERE other_issue = id('${parentId}') AND kind = 50) || ' ' || (SELECT status FROM issue WHERE id = id('${child}')) AS v")"
	[[ "${out##*$'\n'}" == "1 1 1 20" ]]  ||  { printf 'children: %s\n' "${out}"; return 1; }
	out="$(fGitniblet "${dbMain}" comments issue "${child}")"
	grep -qF "Started" <<< "${out}"  ||  { printf 'comments: %s\n' "${out}"; return 1; }
	out="$(fGitniblet "${dbMain}" query "SELECT count(*) FROM audit_trail WHERE parent_id = id('${child}') AND action = 'update'")"
	[[ "${out##*$'\n'}" == "1" ]]  ||  { printf 'audit trail: %s\n' "${out}"; return 1; }
}

## Every table, sorted by id, as text. date_created is left out, since a new
## view stamps it with the replay time; fT_DateCreated watches that.
fDump(){
	local cfg="${1}" t
	for t in issue decision issue_link person component lookups lookup_values; do
		printf '== %s\n' "${t}"
		fGitniblet "${cfg}" query "SELECT * FROM ${t} ORDER BY id" | awk -F '\t' -v OFS='\t' '
			NR == 1 { for (i = 1; i <= NF; i++) if ($i == "date_created") skip = i }
			{ line = ""; for (i = 1; i <= NF; i++) if (i != skip) line = line (line == "" ? "" : OFS) $i; print line }'
	done
}

fT_Replay(){
	[[ -n "${parentId}" ]]  ||  { echo "needs the create test"; return 3; }
	local fresh; fresh="$(fDb_Make fresh "${work}/main/log")"
	fGitniblet "${fresh}" replay > /dev/null
	fDump "${dbMain}" > "${work}/dump-a.txt"; fDump "${fresh}" > "${work}/dump-b.txt"
	diff "${work}/dump-a.txt" "${work}/dump-b.txt"  ||  return 1
	grep -q 'Child item' "${work}/dump-b.txt"  ||  { echo "replayed view has no rows"; return 1; }
}

fT_Queries(){
	[[ -n "${dbMain}" ]]  ||  { echo "needs the seeds test"; return 3; }
	local sql n=0
	# shellcheck disable=2016  ## The backticks are literal, the SQL's own quoting.
	local -r sqlLine='s/^[[:space:]]*SQL:[[:space:]]*`(.*)`[[:space:]]*$/\1/p'
	while IFS= read -r sql; do
		((++n))
		fGitniblet "${dbMain}" query "${sql}" > "${work}/out.txt" 2>&1  ||  { printf '%s\n' "${sql}"; cat "${work}/out.txt"; return 1; }
	done < <(sed -nE "${sqlLine}" "${srcDir}/ddl.queries.shcl")
	((n))  ||  { echo "found no SQL lines"; return 1; }
	printf '%s queries\n' "${n}"
}

## A view rebuilt from the log, as on a fresh clone, should keep each row's
## date_created. Today gitniblet stamps the replay time instead, so this reports a
## skip while that holds and passes once it's fixed.
fT_DateCreated(){
	[[ -n "${parentId}" ]]  ||  { echo "needs the create test"; return 3; }
	local fresh a b
	sleep 1
	fresh="$(fDb_Make datecheck "${work}/main/log")"
	fGitniblet "${fresh}" replay > /dev/null
	a="$(fGitniblet "${dbMain}" query "SELECT date_created FROM issue WHERE id = id('${parentId}')")"
	b="$(fGitniblet "${fresh}" query "SELECT date_created FROM issue WHERE id = id('${parentId}')")"
	[[ "${a##*$'\n'}" == "${b##*$'\n'}" ]]  &&  return 0
	printf 'known gitniblet gap, was %s, now %s\n' "${a##*$'\n'}" "${b##*$'\n'}"
	return 3
}

fT_TrackedLog(){
	local tracked="${repoDir}/gitniblet/issue-tracker_test" db
	[[ -f "${tracked}/txlog.csv" ]]  ||  { echo "no txlog.csv yet"; return 3; }
	db="$(fDb_Make tracked "${tracked}")"
	fGitniblet "${db}" replay > "${work}/out.txt" 2>&1  ||  { cat "${work}/out.txt"; return 1; }
	if grep -q 'warning:' "${work}/out.txt"; then grep 'warning:' "${work}/out.txt"; return 1; fi
}

fT_SyncRefused(){
	local db; db="$(fDb_Make syncme)"
	if fGitniblet "${db}" sync > "${work}/out.txt" 2>&1; then echo "sync ran"; return 1; fi
	grep -qF "sync is refused" "${work}/out.txt"  ||  { cat "${work}/out.txt"; return 1; }
}

declare -i nPass=0 nFail=0 nSkip=0 rc
for t in "${tests[@]}"; do
	IFS='|' read -r id area name fn <<< "${t}"
	fWanted "${area}"  ||  continue
	rc=0; "${fn}" > "${work}/why.txt" 2>&1  ||  rc=$?
	case "${rc}" in
		0)  printf 'PASS %s %s\n' "${id}" "${name}"; ((++nPass)) ;;
		3)  printf 'SKIP %s %s, %s\n' "${id}" "${name}" "$(head -1 "${work}/why.txt")"; ((++nSkip)); continue ;;
		*)  printf 'FAIL %s %s\n' "${id}" "${name}"; ((++nFail)) ;;
	esac
	if [[ -s "${work}/why.txt" ]]; then sed 's/^/\t/' "${work}/why.txt"; fi
done
printf '%s passed, %s failed, %s skipped\n' "${nPass}" "${nFail}" "${nSkip}"
((! nFail))


##	History:
##		- 20261025 JC: Created.
