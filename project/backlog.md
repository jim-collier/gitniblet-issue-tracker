<!-- markdownlint-disable MD007 -- Unordered list indentation -->
<!-- markdownlint-disable MD010 -- No hard tabs -->
<!-- markdownlint-disable MD041 -- First line in a file should be a top-level heading -->

<!-- TOC ignore:true -->
# Project backlog

<!-- TOC ignore:true -->
## Table of contents

<!-- TOC -->

- [Introduction](#introduction)
- [Issues](#issues)
- [Template](#template)

<!-- /TOC -->

## Introduction

Eventually this will all be moved to nano-git-db anyway. This new template is an intermediate effort to make issues going forward more structured and importable. This is a product backlog just for pre-v1.0.0 release.

Items about nano-git-db or shcl are gaps found here. They get fixed in those projects, and close here once a fix is in and this project's tests pass on it.

## Issues

- 20261025-081728: A CI/CD pipeline kicked off by a bash script (`cicd/cicd.bash`): builds, tests, and can commit and push.
	- Status: Waiting on UAT
	- Progress log:
		- 2026-10-25: In. There's nothing to compile, so it syncs, lints, tests, then backs up, commits, and pushes. It takes the shared flags, step lines, run folder, and CPU limits.
	- Test case: `cicd/utility/ddl-test.bash`, IDs dedqv to dedra.

- Feature: Write the first schema, from the backlog template
	- ID: 2026102509013420
	- Type: Feature
	- Status: Waiting on UAT
	- Priority: High
	- Opened: 20261025-090134
	- Opened by: JC
	- Requirements:
		- Start from the nano-git-db issue-tracker demo, which this replaces.
		- An issue has the template's rows. Type, status, priority, and effort are pick lists.
		- Decisions, prereq and related links, comments, and an audit trail.
		- Named queries for open, waiting, critical and high, closed, and everything.
	- Progress log:
		- 2026-10-25: Drafted in `source/ddl.shcl` and `source/ddl.queries.shcl`. Field names and lists are a first pass.
	- Decisions:
		- Lists use the shcl 2.x form, since that's what nano-git-db reads.
		- Git sync is off in the schema until a deployment can set it in its own config.
	- Test case: dedqx, dedqy, dedqz, dedr0 to dedr7.

- Task: Set up the project structure, config, and dev wrapper
	- ID: 2026102509013430
	- Type: Task
	- Status: Waiting on UAT
	- Priority: High
	- Opened: 20261025-090134
	- Opened by: JC
	- Progress log:
		- 2026-10-25: `source/config.shcl`, the log folder, `utility/ngdb-dev.bash`, the license, and the filled-in templates are in. `dev` is the working branch.
	- Test case: dedqv, dedqw, dedr9.

- nano-git-db: a view rebuilt from the log stamps every row's `date_created` with the replay time
	- ID: 2026102509013440
	- Type: Bug
	- Status: Queued
	- Severity: High
	- Opened: 20261025-090134
	- Opened by: JC
	- Steps to reproduce [Bug]:
		- Create a row, then replay the same log into a new view, as on a fresh clone.
	- Incorrect behavior [Bug]: The row's `date_created` is the time of the replay. A replay into the existing view keeps it.
	- Expected behavior [Bug]: `date_created` comes from the log, so every view agrees.
	- Reproduced [Bug]: 2026-10-25, ngdb 1.0.0-beta.2 (ffd8d58-dirty).
	- Test case: dedra. It reports a skip while the bug stands, and passes once it's fixed.

- nano-git-db: a schema with a list can't load clean in both nano-git-db and shcl 3
	- ID: 2026102509013450
	- Type: Bug
	- Status: Queued
	- Severity: High
	- Opened: 20261025-090134
	- Opened by: JC
	- Incorrect behavior [Bug]:
		- nano-git-db reads shcl with the 2.x rules. It takes `row: idx=1, title="x"` and ignores `[a, b]`.
		- shcl 3 refuses the bare form, so `shcl check` fails on every seed row and multi-field index.
		- nano-git-db's own schema for the DDL fails to load in shcl 3, so a DDL can't be checked against it there.
	- Expected behavior [Bug]: nano-git-db reads shcl 3, and its DDL schema loads in shcl 3.
	- Note: The seed rows here are the only list lines. dedqy fails on any other shcl 3 error.
	- Progress log:
		- 2026-10-25: nano-git-db is moving to shclwrap and shcl 3.0. Filed there as 2026102509204445. Once it's in, the seed rows here switch to `[a, b]` and dedqy checks the whole file.

- nano-git-db: per-deployment git sync, set in the config, not the schema
	- ID: 2026102509013460
	- Type: Feature
	- Status: Queued
	- Priority: High
	- Opened: 20261025-090134
	- Opened by: JC
	- Requirements:
		- The sync loop is set by the schema's `git_sync_frequency`, so every deployment of one schema shares it.
		- A test log inside a dev repo needs it off. A real one wants it on.
		- Sync pulls without `--ff-only` and pushes `HEAD`, on whatever branch is checked out. A dev repo wants neither.

- Feature: The tables, fields, and views of a full issue tracker
	- ID: 2026102513400533
	- Type: Feature
	- Status: Queued
	- Priority: High
	- Opened: 20261025-134006
	- Opened by: JC
	- Related IDs: 2026102509013420, 2026102513400563
	- Requirements:
		- Every standard table and field a competent issue tracker has, beyond the backlog template's rows. Projects, components, milestones, labels, people, and attachments, for a start.
		- The common views, such as a Kanban board by status, a nested list by parent, and a plain filtered list.
		- Use nano-git-db's built-in tables, relationships, and views as far as they go, and past that. Each gap gets an item here and a fix in nano-git-db.
	- Reason:
		- This project exists to stress shcl, shclwrap, and nano-git-db until they're feature complete. A thin schema wouldn't find much.

- Feature: An MCP server, from early on
	- ID: 2026102513400563
	- Type: Feature
	- Status: Queued
	- Priority: High
	- Opened: 20261025-134006
	- Opened by: JC
	- Related IDs: 2026102513400533
	- Requirements:
		- An agent can list, read, file, and update issues and their comments, decisions, and links through MCP.
		- It grows with the schema, the TUI, the GUI, and the web UI, not after them.
	- Needs more thought:
		- Whether the server is generic in nano-git-db, for any schema, with only tracker-specific tools here.

- nano-git-db: `empty_ok: no` and `required: yes` don't refuse an empty value
	- ID: 2026102509013470
	- Type: Bug
	- Status: Queued
	- Severity: Avg
	- Opened: 20261025-090134
	- Opened by: JC
	- Steps to reproduce [Bug]: A field with `null_ok: no`, `empty_ok: no`, and `required: yes`. Create a row with it set to `""`.
	- Incorrect behavior [Bug]: The row is created. Only a missing field is refused, by `null_ok: no`.
	- Expected behavior [Bug]: An empty value is refused too.

- nano-git-db: `ngdb ddl` exits 0 on a schema with errors
	- ID: 2026102509013480
	- Type: Bug
	- Status: Queued
	- Severity: Avg
	- Opened: 20261025-090134
	- Opened by: JC
	- Incorrect behavior [Bug]: A type outside the allowed set, an unknown key, a dropped index, and skipped seed rows are all warnings, with exit 0.
	- Expected behavior [Bug]: A schema error fails, so a script can tell. Today the tests here fail on any warning line instead.

- nano-git-db: open a database from a config file, with paths relative to it
	- ID: 2026102509013490
	- Type: Feature
	- Status: Queued
	- Priority: Avg
	- Opened: 20261025-090134
	- Opened by: JC
	- Requirements:
		- Today `--config` takes only a registry folder, and records need absolute paths. ngdb also writes `last_opened` back into the record.
		- A config file of any name and path declares the schema, the tx-log, and the view, each with any name and path. The tx-log's file name is fixed as `txlog.csv` today.
		- `--config` takes a folder, where ngdb looks for `config.shcl`, or a config file by name.
		- Paths in the config are relative to the file, and `${HOME}` works.
		- Keep state like `last_opened` out of that file, so it can be tracked in git.
		- Then `utility/ngdb-dev.bash` can go.

- Feature: Import a project's backlog.md
	- ID: 2026102513400593
	- Type: Feature
	- Status: Queued
	- Priority: Avg
	- Opened: 20261025-134006
	- Opened by: JC
	- Related IDs: 2026102513400533
	- Requirements:
		- Each project moves its own backlog.md into the tracker, one at a time. shcl, shclwrap, and nano-git-db go first.
		- The schema fields follow the template's rows, so the import maps them field by field.
	- Needs more detail:
		- Items in older formats, with no ID or with the ID in the title.
	- Progress log:
		- 2026-10-25: Filed in nano-git-db as 2026102509202821.

- CICD reset: containers
	- ID: 2026102509013500
	- Type: Enhancement
	- Status: Queued
	- Priority: High
	- Opened: 20261025-090134
	- Opened by: JC
	- Requirements:
		- Per `Containers` and the container bullets of `Cleanup after a run` in the shared CICD rules.
		- Sweeping override, 2026-10-24: this supersedes any earlier decision on this project that conflicts with it.
		- The image needs pinned shcl and ngdb builds, plus shellcheck and markdownlint. Everything runs on the host until then, and the run says so in one line.

- CICD reset: merge gate hook
	- ID: 2026102509013510
	- Type: Enhancement
	- Status: Queued
	- Priority: High
	- Opened: 20261025-090134
	- Opened by: JC
	- Requirements:
		- Per `Merge gate` in the shared CICD rules.
		- Sweeping override, 2026-10-24: this supersedes any earlier decision on this project that conflicts with it.
		- A pre-push hook runs `cicd.bash --merge-gate` on a push to `main`. A push that changes only docs skips it, from one list of paths the hook reads.

- CICD reset: CICD process gaps
	- ID: 2026102509013520
	- Type: Enhancement
	- Status: Queued
	- Priority: Avg
	- Opened: 20261025-090134
	- Opened by: JC
	- Requirements:
		- Sweeping override, 2026-10-24: this supersedes any earlier decision on this project that conflicts with it.
		- Pin the shcl and ngdb versions the tests run against. Today the run prints them.
		- A first `--backlog-run-full` and a full run, watched end to end.

- nano-git-db: `query` prints columns in name order, not the order selected
	- ID: 2026102509013530
	- Type: Bug
	- Status: Queued
	- Severity: Low
	- Opened: 20261025-090134
	- Opened by: JC
	- Steps to reproduce [Bug]: `ngdb query <db> "SELECT 'b' AS b, 'a' AS a"`.
	- Incorrect behavior [Bug]: The header is `a b`.
	- Expected behavior [Bug]: `b a`, as selected.

- Move nano-git-db's demo walkthrough and seed script here
	- ID: 2026102509013540
	- Type: Task
	- Status: Queued
	- Priority: Low
	- Opened: 20261025-090134
	- Opened by: JC
	- Requirements:
		- The demo's schema and queries started this one. Its walkthrough and seed script still point at the demo's own files.
		- They need this schema's lookups and field names before they move.
	- Progress log:
		- 2026-10-25: The demo is gone from nano-git-db-floss. Its files are still in that repo's history, under `demos/t7em6_issue-tracker/` at c87f198.

- 20261025-081804: Dev-environment install script (Linux bash, macOS sh, Windows PowerShell), runnable via a single `curl`/`wget` and documented under "how to develop". Clones main, installs dependencies, and states what it will do with an option to abort.

- 20261025-081811: Release-install script per platform, runnable via a single `curl`/`wget` and documented under "how to install". Downloads, installs, and runs the latest release, with an option to abort.

- CICD reset: temp files, safe removal, CPU and priority, standard flags, step output, and test IDs
	- ID: 2026102509013550
	- Type: Enhancement
	- Status: Done
	- Priority: High
	- Opened: 20261025-090134
	- Opened by: JC
	- Requirements:
		- Per `Temp files`, `Safe removal`, `Machine use`, `CICD style guide`, and `Testing` in the shared CICD rules.
		- Sweeping override, 2026-10-24: this supersedes any earlier decision on this project that conflicts with it.
	- Progress log:
		- 2026-10-25: In from the start. Other hosts, the version line, Zig caches, and the macOS runner don't apply, since nothing here is compiled.
	- Test case: The pipeline's own run, since these are how it runs. Each test line has its ID.
	- Acceptance signoff: Self-closed: built in with the pipeline.
	- Closed: 20261025-090134

- The tx-log file is `txlog.csv`, but the layout asks for `tx-log.csv`
	- ID: 2026102509013410
	- Type: Task
	- Status: Done
	- Priority: Avg
	- Opened: 20261025-090134
	- Opened by: JC
	- Requirements:
		- nano-git-db names the file itself, inside `log_dir`. It has no setting for the name.
	- Decisions:
		- 2026-10-25 JC: Use `txlog.csv`. nano-git-db should also take any name and path for it from a config file of any name and path. That's 2026102509013490 here.
	- Test case: Not applicable, since the layout already used `txlog.csv`.
	- Closed: 20261025-092044

## Template

- Notes:

	- Only use rows that you actually need or expect will be filled in. Always fill in the title, ID, Type, Status, Opened and Created by.

	- The ID is the local time to the hundredth of a second. Opened is when it was written down, which may differ. (Use a keyboard macro and possibly something like project 'zuid' to generate.)

	- Status values meaning: Testing means the fix is in and checks are running or still to run. Moot means something else changed that made it irrelevant. Canceled means it still applies but was decided against. Can't reproduce means a real attempt to reproduce it failed.
		- The fix is in, and it waits on one of these:
			- Waiting on automated testing: a slow local suite or an outside test host, which a backlog round runs by itself.
			- Waiting on a full CICD run: a complete pipeline run, with no flags. A person or a round can start it.
			- Waiting on a partial CICD run: a pipeline run with only some stages, such as `--quick --leakcheck`. Also a person or a round.
			- Waiting on UAT: automated testing passed, and a person still has to try it and judge.

	- As issues are worked, and statuses change, place them in correct sorting order within the list:
		- First by status: Waiting for answers, Waiting on UAT, Testing, Waiting on a full CICD run, Waiting on a partial CICD run, Waiting on automated testing, Can't reproduce, Stalled, Started, Queued, Done, Deferred, Canceled, Moot
		- Then by severity|priority: Critical, High, Avg, Low
		- Then by type: Bugs, [not bugs together]

	- Rows marked [Bug] are for bugs only, and rows marked [Feature] for features and enhancements. Priority and Severity share one row and one scale. Priority is for a Feature or Enhancement, and Severity for a Bug. Children are not nested. They sit at the top level and point back with Parent ID.

Template:

- Title
	- ID: YYYYmmDDHHMMSSNN
	- Type: [Bug|Feature|Enhancement|Task]
	- Status: [Queued|Waiting for answers|Waiting on UAT|Waiting on a full CICD run|Waiting on a partial CICD run|Waiting on automated testing|Started|Testing|Stalled|Can't reproduce|Moot|Canceled|Deferred|Done]
	- Needs local test suite run?:
	- Needs external testing:
	- Priority [Feature|Enhancement] | Severity [Bug]: [Critical|High|Avg|Low]
	- Opened:
	- Opened by:
	- Assigned to:
	- Parent ID:
	- Prereq IDs:
	- Related IDs:
	- Target OS:
	- Test environment:
	- Version and build:
	- Requirements  [Feature]:
		- Hierarchical bulleted list.
	- Steps to reproduce [Bug]:
		- …
	- Incorrect behavior [Bug]:
	- Expected behavior [Bug]:
	- Reproduced [Bug]: [No, or when, where and how]
	- Possible cause [Bug]:
	- Actual cause [Bug]:
		- …
	- Estimated effort: [High|Avg|Low]
	- Actual effort: [High|Avg|Low]
	- Progress log:
		- …
	- Decisions:
		- …
	- Actual fix [Bug]:
	- Branch:
	- Commit:
	- Test case: [Reason not applicable, or CI test case #]
	- Acceptance signoff:
	- Superseded by ID:
	- Closed:
