#!/usr/bin/env bash
#  shellcheck source-path=SCRIPTDIR  ## Sourced helpers resolve from this file, not the caller's cwd.
#  shellcheck enable=require-variable-braces  ## Every expansion braced: "${var}", not "$var".

##	Purpose:
##		Regression tests for the pipeline itself: the pre-push hook, the pin
##		bump, and the fallback to this host when there's no docker. Everything
##		runs in a temp folder. Prints one line per test, "PASS|FAIL|SKIP <id>
##		<name>", and exits 1 when any test fails.
##	Syntax:
##		cicd-test.bash [--list]
##	Env:
##		NIT_RUN_DIR: the cicd run's folder. Without it this makes its own.
##	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
##	Licensed under The MIT License (MIT). Full text at:
##		https://mit-license.org/
##	SPDX-License-Identifier: MIT
##	History: At bottom of script.

set -Eeuo pipefail

meDir="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repoDir="$(cd -P -- "${meDir}/../.." && pwd -P)"

# shellcheck source=include/temp-run.bash
source "${meDir}/include/temp-run.bash"

## ID, name, function. IDs never change once given.
declare -a tests=(
	"deegc|pre-push leaves a push to dev alone|fT_HookDev"
	"deegd|pre-push skips the gate for a docs-only push to main|fT_HookDocs"
	"deege|pre-push runs the gate for a push to main that changes source|fT_HookSource"
	"deegf|pre-push runs the gate for a new main, and not for deleting it|fT_HookNewAndDelete"
	"deegg|bump-pins moves one pin to a given commit and refuses a short one|fT_BumpPins"
	"deegh|no docker runs lint and tests on this host, in one line|fT_NoDocker"
)

if [[ "${1:-}" == "--list" ]]; then
	for t in "${tests[@]}"; do IFS='|' read -r id name _ <<< "${t}"; printf '%s %-6s %s\n' "${id}" cicd "${name}"; done
	exit 0
fi

ownRun=""
if [[ -n "${NIT_RUN_DIR:-}" && -d "${NIT_RUN_DIR}" ]]; then work="$(mktemp -d "${NIT_RUN_DIR}/cicd-test.XXXXXX")"
else ownRun="$(fTempRun_Make)"; work="${ownRun}"; fi
fCleanup(){ if [[ -n "${ownRun}" && -d "${ownRun}" ]]; then fSafeRm "${ownRun}" > /dev/null  ||  true; fi; }
trap fCleanup EXIT

## No user config, signing or hooks from this box.
fGit(){ git -c user.name=tester -c user.email=tester@example.com -c commit.gpgsign=false -c core.hooksPath=/dev/null "${@}"; }

## A repo with the real hook and a stand-in cicd.bash that notes its args.
## Commits: base, then a docs-only one, then one that changes source.
hookRepo="" shaBase="" shaDocs="" shaSource=""
fHook_Repo(){
	[[ -z "${hookRepo}" ]]  ||  return 0
	hookRepo="${work}/hookrepo"
	mkdir -p -- "${hookRepo}/cicd/hooks" "${hookRepo}/source" "${hookRepo}/project"
	cp -- "${repoDir}/cicd/hooks/pre-push" "${hookRepo}/cicd/hooks/"
	printf '#!/usr/bin/env bash\necho "$*" > "%s/gate-ran"\n' "${work}" > "${hookRepo}/cicd/cicd.bash"
	chmod +x "${hookRepo}/cicd/cicd.bash"
	(
		cd "${hookRepo}"
		fGit init -q -b main .
		echo a > README.md; echo a > source/ddl.shcl; echo a > project/backlog.md
		fGit add -A; fGit commit -qm base
		echo b > README.md; echo b > project/backlog.md
		fGit add -A; fGit commit -qm docs
		echo b > source/ddl.shcl
		fGit add -A; fGit commit -qm source
	)
	shaSource="$(git -C "${hookRepo}" rev-parse HEAD)"
	shaDocs="$(git -C "${hookRepo}" rev-parse HEAD~1)"
	shaBase="$(git -C "${hookRepo}" rev-parse HEAD~2)"
}

## Runs the hook with one ref line on stdin; returns 0 when the gate ran.
fHook_Gates(){
	fHook_Repo
	rm -f -- "${work}/gate-ran"
	(cd "${hookRepo}" && bash cicd/hooks/pre-push origin "https://example.com/x.git" <<< "${1}")  ||  { echo "hook failed"; return 2; }
	[[ -f "${work}/gate-ran" ]]  ||  return 1
	grep -qxF -- "--merge-gate --quiet" "${work}/gate-ran"  ||  { echo "gate ran as: $(cat "${work}/gate-ran")"; return 2; }
}

zero="0000000000000000000000000000000000000000"

fT_HookDev(){
	fHook_Repo
	local rc=0; fHook_Gates "refs/heads/dev ${shaSource} refs/heads/dev ${shaBase}"  ||  rc=$?
	((rc == 1))  ||  { echo "gate ran, or the hook failed (${rc})"; return 1; }
}

fT_HookDocs(){
	fHook_Repo
	local rc=0; fHook_Gates "refs/heads/main ${shaDocs} refs/heads/main ${shaBase}"  ||  rc=$?
	((rc == 1))  ||  { echo "gate ran, or the hook failed (${rc})"; return 1; }
}

fT_HookSource(){
	fHook_Repo
	fHook_Gates "refs/heads/main ${shaSource} refs/heads/main ${shaDocs}"  ||  { echo "no gate"; return 1; }
}

fT_HookNewAndDelete(){
	fHook_Repo
	fHook_Gates "refs/heads/main ${shaDocs} refs/heads/main ${zero}"  ||  { echo "no gate for a new main"; return 1; }
	local rc=0; fHook_Gates "(delete) ${zero} refs/heads/main ${shaDocs}"  ||  rc=$?
	((rc == 1))  ||  { echo "gate ran for a delete, or the hook failed (${rc})"; return 1; }
}

fT_BumpPins(){
	local pins="${work}/Dockerfile" want="0123456789abcdef0123456789abcdef01234567" ngdbBefore
	cp -- "${repoDir}/cicd/container/Dockerfile" "${pins}"
	ngdbBefore="$(grep '^ARG NGDB_REV=' "${pins}")"
	NIT_PINS_FILE="${pins}" "${repoDir}/cicd/bump-pins.bash" shcl "${want}" > /dev/null
	grep -qxF "ARG SHCL_REV=${want}" "${pins}"  ||  { echo "SHCL_REV didn't move"; return 1; }
	grep -qxF "${ngdbBefore}" "${pins}"  ||  { echo "NGDB_REV moved too"; return 1; }
	if NIT_PINS_FILE="${pins}" "${repoDir}/cicd/bump-pins.bash" ngdb abc123 > /dev/null 2>&1; then echo "took a short commit"; return 1; fi
	grep -qxF "${ngdbBefore}" "${pins}"  ||  { echo "a refused bump changed NGDB_REV"; return 1; }
}

## A nested run of the real cicd.bash, with its own temp root and log folder,
## so it touches neither this run's folder nor the tracked log folder.
fT_NoDocker(){
	local out="${work}/nodocker.txt"
	mkdir -p -- "${work}/nodocker-temp" "${work}/nodocker-logs"
	if ! env -u NIT_IN_CONTAINER -u NIT_STEPS -u NIT_RUN_DIR -u NIT_JOBS_CAP \
		HOST_TEMP="${work}/nodocker-temp" NIT_LOG_DIR="${work}/nodocker-logs" NIT_DOCKER="nit-no-such-docker" \
		"${repoDir}/cicd/cicd.bash" --backlog-run-quick config > "${out}" 2>&1
	then cat "${out}"; return 1; fi
	grep -qxF "Container: no nit-no-such-docker, so lint and tests run on this host, with its own shcl and ngdb." "${out}"  ||  { cat "${out}"; return 1; }
	grep -qF "this host's own, not the pinned builds" "${out}"  ||  { echo "no Tools line for this host"; return 1; }
	[[ -z "$(ls -A "${work}/nodocker-temp/ngdb-issue-tracker" 2> /dev/null)" ]]  ||  { echo "left its run folder behind"; return 1; }
}

declare -i nPass=0 nFail=0 nSkip=0 rc
for t in "${tests[@]}"; do
	IFS='|' read -r id name fn <<< "${t}"
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
