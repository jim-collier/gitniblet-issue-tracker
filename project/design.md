<!-- markdownlint-disable MD007 -- Unordered list indentation -->
<!-- markdownlint-disable MD010 -- No hard tabs -->
<!-- markdownlint-disable MD033 -- No inline html -->
<!-- markdownlint-disable MD055 -- Table pipe style [Expected: leading_and_trailing; Actual: leading_only; Missing trailing pipe] -->
<!-- markdownlint-disable MD041 -- First line in a file should be a top-level heading -->
# Design

Design, requirements, and direction. The active pre-v1.0.0 bug/feature task list lives in `backlog.md`.

## Assumptions

- gitniblet (gitniblet) does all the work. This project is its data: a schema, named queries, a config, and a tx-log.

- It replaces the issue-tracker demo in gitniblet, which gets removed. It started from that demo's files.

- It's developed alongside shcl, shclwrap, and gitniblet. A gap found here is filed here, then fixed there.

- Its main job is to push those projects to feature complete. In order: shcl, shclwrap, gitniblet, then gitniblet's enterprise edition. It should also be a good issue tracker.

- The schema, the TUI, the GUI, the web UI, and the MCP server grow together. The GUI is the enterprise edition's native one, used here from early on.

## Project structure

### Folder structure

The working files are laid out the way a real deployment would be. A deployment can put them anywhere, even apart from each other, since its config says where each one is.

| What    | File
| :---    | :---
| Config  | `source/config.shcl`
| Schema  | `source/ddl.shcl`
| Queries | `source/ddl.queries.shcl`, found by the schema's base name
| Tx-log  | `gitniblet/issue-tracker_test/txlog.csv`
| View    | `${HOME}/.cache/gitniblet/issue-tracker_test/local.sqlite`

- `utility/gitniblet-dev.bash` runs gitniblet against the config.

- `cicd/` has the pipeline and its tests.

### Data flow

- Every write appends to the tx-log. The SQLite view is rebuilt from it, and is never synced.

- Seed rows for the pick lists go into the log on the first replay, not the build. A fresh view needs `replay`.

## Direction decisions

- The schema fields follow the backlog template's rows, so a markdown backlog can move into it field by field.

- Decisions get their own table, not comments, since a fix has to find and respect them. Comments are the progress log.

- Prereq and related links are rows in `issue_link`, one per link. That works today without gitniblet's many-to-many support.

- Lists in the schema use gitniblet's shcl 2.x form, bare and comma separated. shcl 3 refuses that form, and gitniblet doesn't read the bracketed one yet. So the schema follows the reader that opens it. gitniblet is moving to shcl 3 through shclwrap, and the schema switches to `[a, b]` then.

- Git sync is off in the schema. The test log lives inside this repo, and a sync would commit and push to whatever branch is checked out.

## Architecture

### Software stack

- gitniblet, a Go program, reads the schema and keeps the log.

- shcl, the config format, checks the files and reads the config.

- Bash for the dev wrapper and also the pipeline.

### Configuration model

- `source/config.shcl` has the keys an gitniblet registry record has: `name`, `ddl_path`, `log_dir`, and `sqlite_path`.

- A relative path is relative to the config file. `${HOME}` is the only variable, and it's replaced as text, never evaluated.

- gitniblet reads registry records with absolute paths only, and writes `last_opened` back into them. So the wrapper writes its own record from the config, under `registry/` beside the view, and leaves the tracked config alone.

### Saves and persistence

- The log is append-only CSV. Its folder has `.gitattributes` with `merge=union`, so 2 clients' appends combine, and replay sorts entries into one order.

### Testing

- `cicd/utility/ddl-test.bash` runs every check on a copy of the database in a temp folder, never on the tracked log.

- It checks that the config resolves, the schema loads with no warnings, the seed rows replay, lookups and required fields refuse bad values, child rows link up, a fresh replay rebuilds the same view, every named query runs, and the tracked log replays clean.
