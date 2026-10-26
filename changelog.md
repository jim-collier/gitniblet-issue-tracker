# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
## vNEXT - DATE

### Notes

### Added

### Changed

### Removed

### Other work
-->

## Unreleased

### Changed

- The project is now gitniblet-issue-tracker, built on GitNiblet. `utility/gitniblet-dev.bash` replaces `utility/ngdb-dev.bash`, the test log folder is `gitniblet/`, and env vars start with `GITNIBLET_`.

## v1.0.0-beta1

### Notes

### Added

- First schema, with issue, decision, issue_link, person, and component tables, and pick lists for type, status, priority, and effort.

- Named queries for open, waiting, critical and high, closed, and everything.

- `source/config.shcl` and `utility/ngdb-dev.bash`, to open the test database with ngdb.

- `cicd/cicd.bash`, with lint and the schema tests.

### Changed

### Removed

### Other work
