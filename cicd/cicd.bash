#!/bin/bash
#  shellcheck source-path=SCRIPTDIR  ## Sourced helpers resolve from this file, not the caller's cwd.
#  shellcheck disable=2001  ## 'See if you can use ${variable//search/replace} instead.' Complains about good uses of sed.
#  shellcheck disable=2016  ## 'Expressions don't expand in single quotes, use double quotes for that.' I know, and I often want an explicit '$'.
#  shellcheck disable=2034  ## 'variable appears unused.' Complains about valid use of variable indirection (e.g. later use of local -n var=$1)
#  shellcheck disable=2046  ## 'Quote to prevent word-splitting.' (OK for integers.)
#  shellcheck disable=2086  ## 'Double quote to prevent globbing and word splitting.' (OK for integers.)
#  shellcheck disable=2119  ## 'Use foo "$@" if function's $1 should mean script's $1.' Confusing and inapplicable.
#  shellcheck disable=2120  ## 'Foo references arguments, but none are ever passed.' Valid function argument overloading.
#  shellcheck disable=2128  ## 'Expanding an array without an index only gives the element in the index 0.' False hits on associative arrays.
#  shellcheck disable=2155  ## 'Declare and assign separately to avoid masking return values.' Cumbersome and unnecessary. For integers it's sometimes required to even come into existence for counters.
#  shellcheck disable=2162  ## 'read without -r will mangle backslashes.'
#  shellcheck disable=2178  ## 'Variable was used as an array but is now assigned a string.' False hits on associative arrays with e.g. 'local -n assocArray=$1'.
#  shellcheck disable=2181  ## 'Check exit code directly, not indirectly with $?.'
#  shellcheck disable=2317  ## 'Can't reach.' (I.e. an 'exit' is used for debugging - and makes an unusable visual mess.)
## shellcheck disable=2002  ## 'Useless use of cat.'
## shellcheck disable=2004  ## '$/${} is unnecessary on arithmetic variables.' Inappropriate complaining?
## shellcheck disable=2053  ## 'Quote the right-hand sid of = in [[ ]] to prevent glob matching.' Disable for Yoda Notation.
## shellcheck disable=2143  ## 'Use grep -q instead of echo | grep'

##	Purpose: Lint and test the database definition, then commit and push. See fAbout() below.
##	History: At bottom of this file.

##	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
##	Licensed under The MIT License (MIT). Full text at:
##		https://mit-license.org/
##	SPDX-License-Identifier: MIT


#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Constants
if [[ -z "${doQuietly+x}" ]]; then
	declare -r  projectName="gitniblet-issue-tracker"
	declare     dirPath_Base=".."
	declare     gitAutomationScript="${dirPath_Base}/cicd/utility/n8git_backup-and-publish"
	declare  -i doQuietly=0
	## run: the default run. quick, backlog-quick, backlog-full and merge-gate are
	## the shared modes; the last 3 never sync, commit or push.
	declare     runMode="run"
	declare  -a testAreas=()
	declare  -i doPublish=1  doSync=1  doKeepTemp=0  doList=0
	declare  -i doContainer=1
	declare  -i doRemote=1  ## Taken for the shared flag set; nothing runs on other boxes.
	## Lint and tests run in the pinned image from cicd/container/ unless --no-container.
	## No docker, or an image that won't build, falls back to this host with one line.
	declare  -i inContainer=0; [[ "${NIT_IN_CONTAINER:-}" == "1" ]] && inContainer=1
	declare -r  containerImage="gitniblet-issue-tracker-cicd"
	declare -r  containerEngine="${NIT_DOCKER:-docker}"  ## Anything that takes docker's arguments
	declare     aliasNote=""
	declare -r  thisVersion="1.0.0-beta1"
	declare -r  thisCopyrightYear="2026"
	declare -r  thisAuthor="Jim Collier"
	declare  -i wasShown_Version=0  wasShown_Copyright=0  wasShown_About=0  wasShown_Syntax=0
	declare     runDir=""
fi


## Version, copyright, about, syntax (minified but not obfuscated)

fVersion(){ { ((doQuietly)) || ((wasShown_Version)); } && return; wasShown_Version=1;
	fEcho_Clean "${meName} v${thisVersion}" ;:;}

fCopyright(){ { ((doQuietly)) || ((wasShown_Copyright)); } && return; wasShown_Copyright=1; wasShown_Version=1
	fEcho_Clean ""
	fEcho_Clean "${meName}, Copyright © ${thisCopyrightYear} ${thisAuthor}."
	fEcho_Clean "Licensed under The MIT License (MIT). Full text at:"
	fEcho_Clean "  https://mit-license.org/"
	fEcho_Clean "No warranty."
	fEcho_Clean "" ;:;}

fAbout(){ { ((doQuietly)) || ((wasShown_About)); } && return; wasShown_About=1;
	fEcho_Clean ""
	#           X-------------------------------------------------------------------------------X
	fEcho_Clean "CI/CD for the issue tracker's database definition:"
	fEcho_Clean "  • Fast-forward from the remote first, so what's tested is what gets pushed."
	fEcho_Clean "  • Lint the bash scripts, the docs and the shcl files."
	fEcho_Clean "  • Test the DDL, its named queries and the tracked tx-log through gitniblet."
	fEcho_Clean "  • Back up, commit and push."
	#           X-------------------------------------------------------------------------------X
	fEcho_Clean "" ;:;}

fSyntax(){  { ((doQuietly)) || ((wasShown_Syntax)); } && return; wasShown_Syntax=1;
	fEcho_Clean ""
	#           X-------------------------------------------------------------------------------X
	fEcho_Clean "Usage: ${meName} [options]"
	fEcho_Clean "  (no flags)          Sync, lint, test, then back up, commit and push."
	fEcho_Clean "      --quick         The same, since every step here is fast."
	fEcho_Clean "      --long          The same. Also --slow. There are no slow steps yet."
	fEcho_Clean "      --leakcheck, --no-leakcheck"
	fEcho_Clean "                      Taken and ignored, since nothing here leaks."
	fEcho_Clean "      --backlog-run-quick [area...]"
	fEcho_Clean "                      Lint and tests only, or only the test areas named:"
	fEcho_Clean "                      config, ddl, log, cicd. Also --gate."
	fEcho_Clean "      --backlog-run-full"
	fEcho_Clean "                      Every check of the default run."
	fEcho_Clean "      --merge-gate    Every check of the default run, before a merge to main."
	fEcho_Clean "                      Also --ci."
	fEcho_Clean "                      These 3 never sync, commit, push or prompt."
	fEcho_Clean "      --no-publish    Skip backup + publish: no commit, no push."
	fEcho_Clean "      --no-sync       Skip the fast-forward from the remote."
	fEcho_Clean "      --no-container  Lint and test on this host, with its own shcl and gitniblet."
	fEcho_Clean "      --no-remote     Taken. Nothing runs on the other boxes yet."
	fEcho_Clean "      --keep-temp     Keep the run folder and the run's container, and print"
	fEcho_Clean "                      where they are."
	fEcho_Clean "      --list          Print the steps and test IDs these flags would run."
	fEcho_Clean "  -q, --quiet         Run unattended and quiet; flows to publish."
	fEcho_Clean "  -m, --message MSG   Commit message for publish (also --msg; -m MSG or -m=MSG)."
	fEcho_Clean "                      With -q and no -m, a message is auto-generated."
	fEcho_Clean "  -h, --help          Show this."
	fEcho_Clean "  -v, --version       Show version."
	fEcho_Clean ""
	fEcho_Clean "Each run works in \${HOST_TEMP}/${projectName}/<stamp>_<NNN>/, with TMPDIR"
	fEcho_Clean "pointed at it, and removes it at the end, on failure and Ctrl+C too. It also"
	fEcho_Clean "removes run folders older than 2 days whose run.pid is gone. Every step runs"
	fEcho_Clean "at nice 19 and idle I/O, and gitniblet gets half the CPUs, or a quarter when the"
	fEcho_Clean "1-minute load is over half of them."
	fEcho_Clean ""
	fEcho_Clean "Lint and tests run in an image with shcl and gitniblet built from the dev commits"
	fEcho_Clean "pinned in cicd/container/Dockerfile, built the first time it's needed."
	fEcho_Clean "cicd/bump-pins.bash moves the pins. No docker, or an image that won't build,"
	fEcho_Clean "falls back to this host. At the end the run's container goes, then this"
	fEcho_Clean "project's dangling images, its image tags older than the one before the"
	fEcho_Clean "current, and build cache older than a week. NIT_DOCKER names a program that"
	fEcho_Clean "takes docker's arguments."
	#           X-------------------------------------------------------------------------------X
	fEcho_Clean "" ;:;}


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
fMain(){

	local cliMessage=""
	while (($#)); do case "${1}" in
		-q|--quiet)                doQuietly=1                          ; shift ;;
		--quick)                   runMode="quick"                      ; shift ;;
		--long|--slow)             runMode="run"                        ; shift ;;
		--leakcheck|--no-leakcheck)                                       shift ;;
		--gate)                    aliasNote="--gate is another name for --backlog-run-quick."; runMode="backlog-quick"; shift ;;
		--backlog-run-quick)       runMode="backlog-quick"; shift
		                           while (($#)) && [[ "${1}" != -* ]]; do testAreas+=("${1}"); shift; done ;;
		--backlog-run-full)        runMode="backlog-full"               ; shift ;;
		--ci)                      aliasNote="--ci is another name for --merge-gate."; runMode="merge-gate"; shift ;;
		--merge-gate)              runMode="merge-gate"                 ; shift ;;
		--no-publish)              doPublish=0                          ; shift ;;
		--no-sync)                 doSync=0                             ; shift ;;
		--no-container)            doContainer=0                        ; shift ;;
		--no-remote)               doRemote=0                           ; shift ;;
		--keep-temp)               doKeepTemp=1                         ; shift ;;
		--list)                    doList=1                             ; shift ;;
		--message=*|--msg=*|-m=*)  cliMessage="${1#*=}"                 ; shift ;;
		-m|--message|--msg)        cliMessage="${2-}"; shift; (($#)) && shift ;;
		-h|--help)                 fCopyright; fAbout; fSyntax          ; return 0 ;;
		-v|--version)              fVersion                             ; return 0 ;;
		*) fThrowError "Unknown option: '${1}' (try --help)." ;;
	esac; done

	local area
	for area in "${testAreas[@]}"; do
		[[ "${area}" =~ ^(config|ddl|log|cicd)$ ]]  ||  fThrowError "Unknown area: '${area}'. The areas are config, ddl, log and cicd."
	done

	## The backlog and gate modes leave the tree and the remote alone, and never prompt.
	if [[ "${runMode}" == backlog-* || "${runMode}" == "merge-gate" ]]; then
		doPublish=0; doSync=0; doQuietly=1
	fi
	## The run in the container only lints and tests. The outer run does the rest.
	if ((inContainer)); then doContainer=0; doPublish=0; doSync=0; doQuietly=1; fi

	local commitMessage="${cliMessage}"
	if [[ -z "${commitMessage}" ]] && ((doQuietly)); then commitMessage="Updated"; fi

	fMustBeInPath realpath
	fResolvePath dirPath_Base "${dirPath_Base}"; readonly dirPath_Base
	fResolvePath gitAutomationScript "${gitAutomationScript}"; readonly gitAutomationScript

	cd "${dirPath_Base}"
	## The run in the container numbers its steps from the outer run's list.
	if ((inContainer)) && [[ -n "${NIT_STEPS:-}" ]]; then fSteps_Import
	else fSteps_PlanAll; fi

	if ((doList)); then
		local s
		for s in "${stepsOn[@]}"; do fEcho_Clean "Step: ${s}"; done
		for s in "${stepsOff[@]}"; do fEcho_Clean "Off: ${s}"; done
		if fStep_IsOn "Tests"; then fTests --list; fi
		return 0
	fi

	if ((! doQuietly)); then
		fCopyright
		fAbout
		fEcho_Clean "Repo .........................: ${dirPath_Base}"
		fEcho_Clean "Mode .........................: ${runMode}"
		if ((doPublish)); then
			fEcho_Clean "Git commit and push script ...: ${gitAutomationScript}"
			if [[ -n "${commitMessage}" ]]; then fEcho_Clean "Publish commit message .......: \"${commitMessage}\""
			else fEcho_Clean "Publish commit message .......: (prompt below; blank = editor)"; fi
		fi
		fEcho_Clean
		## The go/no-go gate: Ctrl+C here aborts, and there's no y/n prompt.
		if [[ -z "${commitMessage}" ]] && ((doPublish)); then
			read -r -p "Publish commit message (blank = editor; Ctrl+C aborts): " reply
			fEcho_ResetBlankCounter
			[[ -n "${reply}" ]]  &&  commitMessage="${reply}"
		fi
		fEcho_Clean
	fi

	####
	#### MAKEITSO
	####

	## The run in the container uses the outer run's folder, and the outer run logs it.
	if ((inContainer)); then
		runDir="${NIT_RUN_DIR:-}"
		[[ -n "${runDir}" && -d "${runDir}" ]]  ||  fThrowError "NIT_RUN_DIR isn't a folder: '${runDir}'."
	else
		fTempRun_Sweep
		runDir="$(fTempRun_Make)"  ||  fThrowError "Couldn't make a run folder under '${HOST_TEMP}/${tempProject}'."
		runStamp="${runDir##*/}"
		export NIT_RUN_DIR="${runDir}"
		export TMPDIR="${runDir}" TEMP="${runDir}" TMP="${runDir}"

		## The whole run goes to a rotated log, which lint-report.bash reads. A
		## test that starts a nested run points NIT_LOG_DIR elsewhere.
		local dirPath_ArtifactsLint="${NIT_LOG_DIR:-${dirPath_Base}/cicd/artifacts/lint}"
		if mkdir -p "${dirPath_ArtifactsLint}" 2> /dev/null; then
			gfs_rotate "${dirPath_ArtifactsLint}" run log > /dev/null 2>&1  ||  true
			## tee ignores Ctrl+C, or the cleanup at exit writes into a dead pipe and dies.
			exec > >(trap '' INT TERM; exec tee "${dirPath_ArtifactsLint}/run_${serialDT}.log") 2>&1
		fi

		local containerLine
		if ((! doContainer)); then containerLine="Container: off (--no-container), so lint and tests run on this host, with its own shcl and gitniblet."
		elif fContainer_Check; then
			useContainer=1
			containerLine="Container: ${containerTag} for lint and tests, at --cpus ${NIT_JOBS_MAX}, with shcl ${pinShcl:0:8} and gitniblet ${pinGitniblet:0:8} from their dev branches."
		else containerLine="Container: ${containerWhy}, so lint and tests run on this host, with its own shcl and gitniblet."
		fi
		local -a headerLines=("CPUs: ${NIT_CORES}, load ${NIT_LOAD}. gitniblet gets half, or a quarter when the load is over half.")
		headerLines+=("${containerLine}")
		[[ -z "${aliasNote}" ]]  ||  headerLines+=("${aliasNote}")
		fSteps_Header "${projectName} CI/CD, ${runMode}" "${headerLines[@]}"
	fi

	if ((! inContainer)) && fStep "Sync from remote"; then
		fSync
		fStep_End
	fi

	if ((useContainer)) && fContainer_Ready; then
		fStage_Container
	else
		if fStep "Lint"; then
			fLint
			fStep_End
		fi

		if fStep "Tests"; then
			fTests
			fStep_End
		fi
	fi
	((! inContainer))  ||  return 0

	if fStep "Backup + publish"; then
		local -a gitArgs=()
		if ((doQuietly));                then gitArgs+=(--quiet); fi
		if [[ -n "${commitMessage}" ]];  then gitArgs+=("--message=${commitMessage}"); fi
		doPromptToContinue=0  "${gitAutomationScript}"  "${gitArgs[@]}"
		fStep_End
	fi

	fSteps_Footer "${projectName} CI/CD: done; PASS, ${#stepsOn[@]} steps"
}


## The database tests, then the pipeline's own. Says which shcl and gitniblet ran them.
fTests(){
	local -a dbAreas=() area
	local -i doCicd=1
	if ((${#testAreas[@]})); then
		doCicd=0
		for area in "${testAreas[@]}"; do if [[ "${area}" == "cicd" ]]; then doCicd=1; else dbAreas+=("${area}"); fi; done
	fi
	if [[ "${1:-}" == "--list" ]]; then
		if ((! ${#testAreas[@]} || ${#dbAreas[@]})); then "${dirPath_Base}/cicd/utility/ddl-test.bash" --list "${dbAreas[@]}"; fi
		if ((doCicd)); then "${dirPath_Base}/cicd/utility/cicd-test.bash" --list; fi
		return 0
	fi
	fMustBeInPath shcl
	fMustBeInPath "${GITNIBLET_BIN:-gitniblet}"
	local where="this host's own, not the pinned builds"
	((! inContainer))  ||  where="pinned at shcl ${NIT_PIN_SHCL:0:8} and gitniblet ${NIT_PIN_GITNIBLET:0:8}"
	fEcho_Clean "Tools: $(shcl --version 2>&1 | head -1); $("${GITNIBLET_BIN:-gitniblet}" --version 2>&1 | head -1); ${where}"
	if ((! ${#testAreas[@]} || ${#dbAreas[@]})); then
		"${dirPath_Base}/cicd/utility/ddl-test.bash" "${dbAreas[@]}"  ||  fThrowError "Tests failed; the output is above."
	fi
	if ((doCicd)); then
		"${dirPath_Base}/cicd/utility/cicd-test.bash"  ||  fThrowError "Tests failed; the output is above."
	fi
}


## Every step in run order, on or off, with why it's off.
fSteps_PlanAll(){
	local why
	why="";  ((doSync))  ||  why="--no-sync";  [[ "${runMode}" != backlog-* && "${runMode}" != "merge-gate" ]]  ||  why="${runMode} doesn't sync"
	fStep_Plan "Sync from remote" "${why}"
	fStep_Plan "Lint"
	fStep_Plan "Tests"
	why="";  ((doPublish))  ||  why="--no-publish";  [[ "${runMode}" != backlog-* && "${runMode}" != "merge-gate" ]]  ||  why="${runMode} doesn't publish"
	fStep_Plan "Backup + publish" "${why}"
}

fStep_IsOn(){ local s; for s in "${stepsOn[@]}"; do [[ "${s}" == "${1}" ]]  &&  return 0; done; return 1; }

## Opens a step that's planned, after checking the load again.
fStep(){
	fStep_Start "${1}"  ||  return 1
	local busy=""
	fCpuLimit
	((! NIT_BUSY))  ||  busy=", busy"
	fEcho_Clean "Jobs: ${NIT_JOBS} of ${NIT_CORES} CPUs, load ${NIT_LOAD}${busy}"
}

## gitsby picks the account from the folder; plain git where it isn't installed.
fGit(){ if command -v gitsby > /dev/null; then gitsby raw git "${@}"; else git "${@}"; fi; }

## Fetch, then fast-forward when only behind, stashing around it. Diverged stops
## the run; offline or no upstream warns and goes on.
fSync(){
	local upstream ahead behind
	if ! upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2> /dev/null)"; then
		fEcho_Clean "WARN no upstream for $(git branch --show-current), so no sync."; return 0
	fi
	if ! fGit fetch --quiet; then fEcho_Clean "WARN fetch failed, so no sync. Offline?"; return 0; fi
	read -r ahead behind < <(git rev-list --left-right --count "HEAD...${upstream}")
	if ((behind == 0)); then fEcho_Clean "Up to date with ${upstream} (${ahead} ahead)."; return 0; fi
	((ahead == 0))  ||  fThrowError "Diverged from ${upstream}: ${ahead} ahead, ${behind} behind. Merge or pull by hand first."
	local -i stashed=0
	if [[ -n "$(git status --porcelain)" ]]; then fGit stash push --include-untracked --quiet -m "cicd sync"; stashed=1; fi
	fGit merge --ff-only --quiet "${upstream}"
	((! stashed))  ||  fGit stash pop --quiet
	fEcho_Clean "Fast-forwarded ${behind} commit(s) from ${upstream}."
}

## shellcheck on the first-party bash, markdownlint on the docs. shcl and gitniblet
## checks of the database files are tests, so they sit in ddl-test.bash.
## n8git_backup-and-publish and gfs-rotate.bash are copied as-is from elsewhere,
## and the license, contributing and conduct docs are left as their templates came.
fLint(){
	local -a bashFiles=() mdFiles=()
	mapfile -t bashFiles < <(git ls-files -co --exclude-standard -- '*.bash' 'cicd/hooks/*' | grep -vF 'gfs-rotate.bash')
	((${#bashFiles[@]}))  ||  fThrowError "Lint found no bash files."
	fEcho_Clean "shellcheck: ${#bashFiles[@]} files"
	shellcheck -x -- "${bashFiles[@]}"  ||  fThrowError "shellcheck failed; the output is above."
	mapfile -t mdFiles < <(git ls-files -co --exclude-standard -- '*.md' | grep -vxE 'license\.md|contributing\.md|code_of_conduct\.md')
	((${#mdFiles[@]}))  ||  fThrowError "Lint found no markdown files."
	if command -v markdownlint > /dev/null; then
		fEcho_Clean "markdownlint: ${#mdFiles[@]} files"
		markdownlint -- "${mdFiles[@]}"  ||  fThrowError "markdownlint failed; the output is above."
	else
		fEcho_Clean "WARN markdownlint isn't installed, so the docs weren't linted."
	fi
}

#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Sets containerTag and the pins, or containerWhy when the run should stay on
## this host. Prints nothing, so the first section can say which it is.
declare containerTag="" containerWhy="" pinShcl="" pinGitniblet="" runStamp=""
declare -i useContainer=0  dockerUsed=0  imagePassed=0  ## For the cleanup at exit
fContainer_Check(){
	if [[ "$(uname -m)" != "x86_64" ]]; then containerWhy="the image is x86_64 only"
	elif ! command -v "${containerEngine}" &>/dev/null; then containerWhy="no ${containerEngine}"
	elif ! "${containerEngine}" version --format '{{.Server.Version}}' &>/dev/null; then containerWhy="${containerEngine} isn't answering"
	fi
	[[ -z "${containerWhy}" ]]  ||  return 1
	dockerUsed=1

	local -r recipe="${dirPath_Base}/cicd/container"
	## Called as an if condition, where set -e is off, so a throw has to exit.
	[[ -f "${recipe}/Dockerfile" ]]  ||  { fThrowError "Missing the container recipe: '${recipe}/Dockerfile'."; exit 1; }
	pinShcl="$(sed -n 's/^ARG SHCL_REV=//p' "${recipe}/Dockerfile")"
	pinGitniblet="$(sed -n 's/^ARG GITNIBLET_REV=//p' "${recipe}/Dockerfile")"
	[[ "${pinShcl}" =~ ^[0-9a-f]{40}$ && "${pinGitniblet}" =~ ^[0-9a-f]{40}$ ]]  ||  { fThrowError "SHCL_REV and GITNIBLET_REV in '${recipe}/Dockerfile' have to be full commits."; exit 1; }

	## Tagged by the recipe's hash, so an edited recipe or pin can't run on the old image.
	containerTag="${containerImage}:$(cat "${recipe}/Dockerfile" "${recipe}/package.json" "${recipe}/package-lock.json" | sha256sum | cut -c1-12)"
	return 0
}

## Builds the image if it isn't there yet. Returns 1 with one line when the run
## should stay on this host after all.
fContainer_Ready(){
	"${containerEngine}" image inspect "${containerTag}" &>/dev/null  &&  return 0
	fEcho_Clean "Container image: building ${containerTag}"
	## nice reaches only the client; the build itself runs in the daemon, so JOBS caps cargo and go.
	if ! nice -n 19 "${containerEngine}" build --label "dev.project=${projectName}" --label "dev.run=${runStamp}" \
		--build-arg "JOBS=${NIT_JOBS}" -t "${containerTag}" "${dirPath_Base}/cicd/container"
	then
		fEcho_Clean "Container: ${containerTag} didn't build, so lint and tests run on this host, with its own shcl and gitniblet."; return 1
	fi
}

## The repo at its own path, read-only, as the caller's uid, so paths in the
## output still point at something and nothing in it can be rewritten. The run
## inside numbers its steps from this run's list, checks the load before each
## one, and never takes more than the container's --cpus.
fStage_Container(){
	fCpuLimit
	fSteps_Export
	local -a innerArgs=(-q --no-container)
	case "${runMode}" in
		quick)          innerArgs+=(--quick) ;;
		backlog-quick)  innerArgs+=(--backlog-run-quick "${testAreas[@]}") ;;
		backlog-full)   innerArgs+=(--backlog-run-full) ;;
		merge-gate)     innerArgs+=(--merge-gate) ;;
	esac
	local -a runArgs=(--init
		--name "${projectName}-${runStamp}-lint-test" --label "dev.project=${projectName}" --label "dev.run=${runStamp}"
		--cpus "${NIT_JOBS_MAX}" --cpu-shares 256 --user "$(id -u):$(id -g)"
		-v "${dirPath_Base}:${dirPath_Base}:ro" -w "${dirPath_Base}"
		-v "${runDir}:${runDir}" -e NIT_RUN_DIR -e HOST_TEMP -e TMPDIR -e TEMP -e TMP -e NIT_IN_CONTAINER=1
		-e NIT_STEPS -e "NIT_JOBS_CAP=${NIT_JOBS_MAX}")
	((doKeepTemp))  ||  runArgs+=(--rm)
	## The host's time zone, for the step lines' local time.
	[[ ! -f /etc/localtime ]]  ||  runArgs+=(-v /etc/localtime:/etc/localtime:ro)
	[[ -z "${TZ:-}" ]]  ||  runArgs+=(-e TZ)
	## A worktree's .git file points at the main checkout's.
	local gitCommon
	gitCommon="$(git -C "${dirPath_Base}" rev-parse --path-format=absolute --git-common-dir)"
	[[ "${gitCommon}" == "${dirPath_Base}/"* ]]  ||  runArgs+=(-v "${gitCommon}:${gitCommon}:ro")

	## In the background, since Ctrl+C would only reach the container's init.
	## Ctrl+C kills the short sleep below at once, and the cleanup at exit
	## removes the container.
	fEcho_Clean "Container: running ${projectName}-${runStamp}-lint-test"
	"${containerEngine}" run "${runArgs[@]}" "${containerTag}" nice -n 19 bash "${dirPath_Base}/cicd/cicd.bash" "${innerArgs[@]}" &
	local ctrPid=$!
	while kill -0 "${ctrPid}" 2> /dev/null; do sleep 0.5; done
	wait "${ctrPid}"  ||  fThrowError "The run in the container failed; its output is above."
	fEcho_WasLastEchoBlank_Set 1  ## the run inside closed its last step with a blank line
	imagePassed=1
}

## Only what carries this project's label, and never rmi -f, so an image a
## container still uses stays. The run's container goes first.
fContainer_Cleanup(){
	((dockerUsed))  ||  return 0
	local -a ids=() removed=() oldTags=()
	local before after tag
	before="$(fDocker_Bytes)"

	mapfile -t ids < <("${containerEngine}" ps -aq --filter "label=dev.project=${projectName}" --filter "label=dev.run=${runStamp}" 2> /dev/null)
	if ((${#ids[@]})); then
		if ((doKeepTemp)); then
			"${containerEngine}" stop "${ids[@]}" &> /dev/null  ||  true
			fEcho_Clean "Kept container ${projectName}-${runStamp}-lint-test (--keep-temp)."
		else
			"${containerEngine}" rm -f "${ids[@]}" &> /dev/null  &&  removed+=("${#ids[@]} container(s)")
		fi
	fi

	mapfile -t ids < <("${containerEngine}" image ls -q --filter "label=dev.project=${projectName}" --filter dangling=true 2> /dev/null)
	if ((${#ids[@]})) && "${containerEngine}" rmi "${ids[@]}" &> /dev/null; then removed+=("${#ids[@]} dangling image(s)"); fi

	## Newest first. Keep the tag that just passed and the one before it.
	if ((imagePassed)) && [[ -n "${containerTag}" ]]; then
		mapfile -t oldTags < <("${containerEngine}" image ls "${containerImage}" --filter "label=dev.project=${projectName}" \
			--format '{{.Repository}}:{{.Tag}}' 2> /dev/null | grep -vxF -e "${containerTag}" -e "${containerImage}:<none>" | tail -n +2)
		for tag in "${oldTags[@]}"; do "${containerEngine}" rmi "${tag}" &> /dev/null  &&  removed+=("${tag}"); done
	fi

	"${containerEngine}" builder prune -f --filter until=168h &> /dev/null  ||  true

	after="$(fDocker_Bytes)"
	local freed="?"
	[[ "${before}" =~ ^[0-9]+$ && "${after}" =~ ^[0-9]+$ ]]  &&  freed="$(numfmt --to=si --suffix=B $(( before > after ? before - after : 0 )))"
	fEcho_Clean "Docker cleanup: removed ${removed[*]:-no containers or images}, plus week-old build cache; freed about ${freed}."
}

## Total of docker system df's sizes, in bytes.
fDocker_Bytes(){
	"${containerEngine}" system df --format '{{.Size}}' 2> /dev/null | numfmt --from=si --suffix=B --invalid=ignore 2> /dev/null \
		| awk '{ sub(/B$/, ""); t += $1 } END { printf "%d\n", t }'
}


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
fCleanup(){
	## A step still open here is the one that failed or was interrupted.
	fStep_Fail
	## Not inside the container: the outer run owns the folder and the docker side.
	if ((! inContainer)); then
		fContainer_Cleanup  ||  true
		if [[ -n "${runDir}" && -d "${runDir}" ]]; then
			if ((doKeepTemp)); then fEcho_Clean "Kept the run folder: ${runDir}"
			else fSafeRm "${runDir}" > /dev/null  ||  true; fi
		fi
	fi
	fEcho_Clean
}


#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Generic functions

## Resolves a path in place by name; an empty result throws unless arg 3 is 0.
fResolvePath(){
	local -n path_k3vd="${1}"
	local resolved
	resolved="$(realpath -e -- "${2}" 2> /dev/null || true)"
	[[ -n "${resolved}" ]]  ||  [[ "${3:-1}" == "0" ]]  ||  fThrowError "Path not found: '${2}'"
	path_k3vd="${resolved}"
}

fMustBeInPath(){ command -v "${1}" > /dev/null  ||  fThrowError "Not found in PATH: ${1}"; }


## Echo-related (minified but not obfuscated)
declare -gi _wasLastEchoBlank=0
declare -gi _isEchoInRawInlineMode=0
fEcho_ResetBlankCounter()     { _wasLastEchoBlank=0;      }
fEcho_WasLastEchoBlank_Set()  { { [[ "${1:-}" == "1" ]] && _wasLastEchoBlank=1; } || _wasLastEchoBlank=0;  }
fEcho_WasLastEchoBlank_Get()  { { ((_wasLastEchoBlank > 0)) && return 0; } || return 1; }
fEcho_IsInRawInlineMode_Set() { { [[ "${1:-}" == "1" ]] && _isEchoInRawInlineMode=1; } || { _isEchoInRawInlineMode=0; _wasLastEchoBlank=0; echo; }; }  ## Script it telling fEcho* that something is going to be echoing to the screen in non-linefeed mode without its knowledge. (E.g. "echo -n 'something: '".)
fEcho_IsInRawInlineMode_Get() { { ((_isEchoInRawInlineMode)) && return 0; } || return 1; }
fEcho_Clean_byref(){
	## Validate nameref args:
	[[ -v 1  ]] || fThrowError "Calling function must pass a nameref to supply the input value to this function, as arg1 (string to echo)."
	## Gather args
	local -n ptr_ToEcho_t5jf2=$1
	## Logic
	((_isEchoInRawInlineMode)) && fEcho_IsInRawInlineMode_Set 0
	if [[ -n "${ptr_ToEcho_t5jf2}" ]]; then
		echo -e "${ptr_ToEcho_t5jf2}"
		_wasLastEchoBlank=0
	elif [[ $_wasLastEchoBlank -eq 0 ]]; then
		echo
		_wasLastEchoBlank=1
	fi
}
fEcho_Clean()        { local -r toEcho="${1:-}"; fEcho_Clean_byref toEcho; }
fEcho()              { { [[ -z "${1:-}" ]] && fEcho_Clean ""; } || { local -r toEcho="[ ${1:-} ]"; fEcho_Clean_byref toEcho; }; }
fEcho_Force()        { _wasLastEchoBlank=0; fEcho "${1:-}"; }
fEcho_Clean_Force()  { _wasLastEchoBlank=0; local -r toEcho="${1:-}"; fEcho_Clean_byref toEcho; }
declare -r _hr="•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••"
fEcho_Section()      { fEcho_Clean; fEcho_Clean_Force "${_hr}"; fEcho "${1:-}"; }

## Error-handling
declare -i _wasCleanupRun=0  ## Managed internally by this suite.
declare -i _doExitOnThrow=0    ## Managed internally by this suite.
declare -i _ErrVal=0         ## Set by this suite, but managed by calling functions. Think of it as an extended '$?' that doesn't immediately clear.
_fSingleExitPoint(){
	local -r signal="${1:-}"
	local -r lineNum="${2:-}"
	local -r exitCode="${3:-}"
	local -r errMsg="${4:-}"
	local -r errCommand="$BASH_COMMAND"
	_ErrVal=$exitCode
	if [[ "${signal}" == "INT" ]]; then
		fEcho_Force
		echo "User interrupted." >&2
		fEcho_ResetBlankCounter
		fCleanup  ## User cleanup
		exit 1
	elif [[ "${exitCode}" != "0" ]] && [[ "${exitCode}" != "1" ]]; then  ## Clunky string compare is less likely to fail than integer
		fEcho_Clean
		echo -e "Signal .....: '${signal}'"      >&2
		echo -e "Err# .......: '${exitCode}'"    >&2
	#	echo -e "Message ....: '${errMsg}'"      >&2
		echo -e "At line# ...: '${lineNum}'"     >&2
		echo -e "Command# ...: '${errCommand}'"  >&2
		fEcho_Clean_Force
		fCleanup  ## User cleanup
	else
		fCleanup  ## User cleanup
	fi ;}
_fTrap_Exit(){
	if [[ "${_wasCleanupRun}" == "0" ]]; then  ## String compare is less to fail than integer
		_wasCleanupRun=1
		_fSingleExitPoint "${@}"
	fi ;}
_fTrap_Error(){
	if [[ "${_wasCleanupRun}" == "0" ]]; then  ## String compare is less to fail than integer
		_wasCleanupRun=1
		fEcho_ResetBlankCounter
		_fSingleExitPoint "${@}"
	fi ;}
_fTrap_Error_Ignore(){ _ErrVal=1; true;  return 0; }
_fTrap_Error_Soft(){   _ErrVal=1; false; return 1; }
fThrowError(){
	local errMsg="${1:-}"           ; [[ -z "${errMsg}"      ]] && errMsg="An error occurred."
	local meNameLocal="${meName:-}"
	[[ -z "${meNameLocal}" ]] && meNameLocal="$(basename "${BASH_SOURCE[0]}")"
	[[ -n "${meNameLocal}" ]] && errMsg="${meNameLocal}: ${errMsg}"
	local callStack=""
	for (( i = 1; i < ${#FUNCNAME[@]}; i++ )); do
		[[ "${FUNCNAME[i]}" =~ main|source ]] && continue
		[[ -n "${callStack}" ]] && callStack="${callStack}, "; callStack="${callStack}${FUNCNAME[i]}()"
	done;:
	[[ -n "${callStack}" ]] && callStack="Reverse call stack: ${callStack}"
	fEcho_Clean; echo -e "${errMsg}\n${callStack}" >&2; fEcho_ResetBlankCounter
	_ErrVal=1
	{ ((_doExitOnThrow)) && exit 1; } || return 1; }
fDefineTrap_Error_Fatal(){        :; _ErrVal=0; _doExitOnThrow=0; trap '_fTrap_Error         ERR    ${LINENO}  $?  $_' ERR; set -e; } ## Standard; exits script on any caught error; but 'set -e' has known inconsistencies catching or ignoring errors.
fDefineTrap_Error_ExitOnThrow(){  :; _ErrVal=0; _doExitOnThrow=0; trap '_fTrap_Error         ERR    ${LINENO}  $?  $_' ERR; set +e; } ## Only exits script on fThrowError().
fDefineTrap_Error_Soft(){         :; _ErrVal=0; _doExitOnThrow=0; trap '_fTrap_Error_Soft    ERR    ${LINENO}  $?  $_' ERR; set -e; } ## Returns error code of 1 on error.
fDefineTrap_Error_Ignore(){       :; _ErrVal=0; _doExitOnThrow=0; trap '_fTrap_Error_Ignore  ERR    ${LINENO}  $?  $_' ERR; set +e; } ## Eats errors and returns true.
fDefineTrap_Error_Fatal
trap '_fTrap_Error SIGHUP  ${LINENO} $? $_' SIGHUP
trap '_fTrap_Error SIGINT  ${LINENO} $? $_' SIGINT    ## CTRL+C
trap '_fTrap_Error SIGTERM ${LINENO} $? $_' SIGTERM
trap '_fTrap_Exit  EXIT    ${LINENO} $? $_' EXIT
trap '_fTrap_Exit  INT     ${LINENO} $? $_' INT
trap '_fTrap_Exit  TERM    ${LINENO} $? $_' TERM



#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
# Script entry point

 set -u
 set -e
 set -E
 set   -o pipefail
 shopt -s inherit_errexit
 shopt -s dotglob
 shopt -s globstar

if [[ -z "${serialDT+x}" ]]; then
	declare -r mePath="$(realpath -e "${BASH_SOURCE[0]}")"
	declare -r meName="$(basename "${mePath}")"
	declare -r meDir="$(dirname "${mePath}")"
	declare -r serialDT="$(date "+%Y%m%d-%H%M%S")"
fi

cd "${meDir}"

## Half the CPUs, a quarter when busy, exported as GOMAXPROCS for gitniblet. Also
## drops this run to nice 19 and idle I/O, which every step inherits.
# shellcheck source=utility/include/cpu-limit.bash
source "${meDir}/utility/include/cpu-limit.bash"
# shellcheck source=utility/include/gfs-rotate.bash
source "${meDir}/utility/include/gfs-rotate.bash"
# shellcheck source=utility/include/temp-run.bash
source "${meDir}/utility/include/temp-run.bash"
# shellcheck source=utility/include/steps.bash
source "${meDir}/utility/include/steps.bash"

fMain "${@}"


##	Script history:
##		- 20261025 JC: Created from the gitniblet cicd.bash, for a project with nothing to compile.
