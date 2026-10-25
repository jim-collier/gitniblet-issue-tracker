<!-- markdownlint-disable MD007 -- Unordered list indentation -->
<!-- markdownlint-disable MD010 -- No hard tabs -->
<!-- markdownlint-disable MD033 -- No inline html -->
<!-- markdownlint-disable MD055 -- Table pipe style [Expected: leading_and_trailing; Actual: leading_only; Missing trailing pipe] -->
<!-- markdownlint-disable MD041 -- First line in a file should be a top-level heading -->
# Design

Design, requirements, and direction. The active pre-v1.0.0 bug/feature task list lives in `backlog.md`.

## Assumptions

- nano-git-db (ngdb) does all the work. This project is its data: a schema, named queries, a config, and a tx-log.

- It replaces the issue-tracker demo in nano-git-db, which gets removed. It started from that demo's files.

- It's developed alongside shcl, shclwrap, and nano-git-db. A gap found here is filed here, then fixed there.

## Project structure

### Folder structure

The working files are laid out the way a real deployment would be. A deployment can put them anywhere, even apart from each other, since its config says where each one is.

| What    | File
| :---    | :---
| Config  | `source/config.shcl`
| Schema  | `source/ddl.shcl`
| Queries | `source/ddl.queries.shcl`, found by the schema's base name
| Tx-log  | `ngdb/issue-tracker_test/txlog.csv`
| View    | `${HOME}/.cache/ngdb/issue-tracker_test/local.sqlite`

- `utility/ngdb-dev.bash` runs ngdb against the config.

- `cicd/` has the pipeline and its tests.

### Data flow

- Every write appends to the tx-log. The SQLite view is rebuilt from it, and is never synced.

- Seed rows for the pick lists go into the log on the first replay, not the build. A fresh view needs `replay`.

## Direction decisions

- The schema fields follow the backlog template's rows, so a markdown backlog can move into it field by field.

- Decisions get their own table, not comments, since a fix has to find and respect them. Comments are the progress log.

- Prereq and related links are rows in `issue_link`, one per link. That works today without ngdb's many-to-many support.

- Lists in the schema use ngdb's shcl 2.x form, bare and comma separated. shcl 3 refuses that form, and ngdb doesn't read the bracketed one yet. So the schema follows the reader that opens it. nano-git-db is moving to shcl 3 through shclwrap, and the schema switches to `[a, b]` then.

- Git sync is off in the schema. The test log lives inside this repo, and a sync would commit and push to whatever branch is checked out.

## Architecture

### Software stack

- ngdb, a Go program, reads the schema and keeps the log.

- shcl, the config format, checks the files and reads the config.

- Bash for the dev wrapper and also the pipeline.

### Configuration model

- `source/config.shcl` has the keys an ngdb registry record has: `name`, `ddl_path`, `log_dir`, and `sqlite_path`.

- A relative path is relative to the config file. `${HOME}` is the only variable, and it's replaced as text, never evaluated.

- ngdb reads registry records with absolute paths only, and writes `last_opened` back into them. So the wrapper writes its own record from the config, under `registry/` beside the view, and leaves the tracked config alone.

### Saves and persistence

- The log is append-only CSV. Its folder has `.gitattributes` with `merge=union`, so 2 clients' appends combine, and replay sorts entries into one order.

### Testing

- `cicd/utility/ddl-test.bash` runs every check on a copy of the database in a temp folder, never on the tracked log.

- It checks that the config resolves, the schema loads with no warnings, the seed rows replay, lookups and required fields refuse bad values, child rows link up, a fresh replay rebuilds the same view, every named query runs, and the tracked log replays clean.
