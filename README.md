<!-- markdownlint-disable MD007 -- Unordered list indentation -->
<!-- markdownlint-disable MD010 -- No hard tabs -->
<!-- markdownlint-disable MD033 -- No inline html -->
<!-- markdownlint-disable MD055 -- Table pipe style [Expected: leading_and_trailing; Actual: leading_only; Missing trailing pipe] -->
<!-- markdownlint-disable MD041 -- First line in a file should be a top-level heading -->
<div align="center">

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](license.md)
![Lifecycle: Alpha](https://img.shields.io/badge/Lifecycle-Alpha-orange)
![Support](https://img.shields.io/badge/Support-Maintained-brightgreen)

</div>
<!--
[![!#/bin/bash](https://img.shields.io/badge/-%23!%2Fbin%2Fbash-1f425f.svg?logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![made-with-python](https://img.shields.io/badge/Made%20with-Python-1f425f.svg)](https://www.python.org/)
[![made-with-rust](https://img.shields.io/badge/Made%20with-Rust-1f425f.svg)](https://www.rust-lang.org/)
![Go](https://img.shields.io/badge/Go-00ADD8?logo=go&logoColor=white)
![Made with](https://img.shields.io/badge/Made%20with-C%2B%2B-brightgreen?style=plastic)
![Made with](https://img.shields.io/badge/Made%20with-Unreal%20Engine-critical?style=plastic)
[![made-with-javascript](https://img.shields.io/badge/Made%20with-JavaScript-1f425f.svg)](https://www.javascript.com)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](license.md)
![License: GPL v2](https://img.shields.io/badge/License-GPLv2-blue.svg)
[![License: GPL v2+](https://img.shields.io/badge/License-GPLv2%2B-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)
![Lifecycle: Alpha](https://img.shields.io/badge/Lifecycle-Alpha-orange)
![Lifecycle: Beta](https://img.shields.io/badge/Lifecycle-Beta-yellow)
![Lifecycle: RC](https://img.shields.io/badge/Lifecycle-RC-blue)
![Lifecycle: Stable](https://img.shields.io/badge/Lifecycle-Stable-brightgreen)
![Lifecycle: Deprecated](https://img.shields.io/badge/Lifecycle-Deprecated-red)
![Status: Deprecated](https://img.shields.io/badge/Status-Deprecated-orange)
![Status: Archived](https://img.shields.io/badge/Status-Archived-lightgrey)
![Lifecycle: EOL](https://img.shields.io/badge/Lifecycle-EOL-lightgrey)
![Coverage](https://img.shields.io/badge/Coverage-25%25-red)
![Coverage](https://img.shields.io/badge/Coverage-50%25-orange)
![Coverage](https://img.shields.io/badge/Coverage-75%25-yellow)
![Coverage](https://img.shields.io/badge/Coverage-90%25-brightgreen)
![Status: Passing](https://img.shields.io/badge/Status-Passing-brightgreen)
![Status: Failing](https://img.shields.io/badge/Status-Failing-red)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/MY_GITHUB_NAME?logo=GitHub%20Sponsors&style=social)](https://github.com/sponsors/MY_GITHUB_NAME)
-->

<!-- TOC ignore:true -->
# NGDB Issue Tracker

<!--
<table style="border: none; border-collapse: collapse;">
	<tr style="border: none; border-collapse: collapse;">
		<td style="border: none; border-collapse: collapse;"><img src="assets/logo.png" alt="Logo" width="320"/></td>
		<td style="border: none;">An issue tracker built as a nano-git-db database. It's one schema file and a plain CSV log that syncs and merges through git, with no server to run.</td>
	</tr>
</table>
<p align="center"><img src="assets/logo.png" alt="" width="128"></p>
-->

A simple but full-featured issue management system, built as a nano-git-db database. The main deliverable is a `.shcl`-format schema file for `nano-git-db`.

The result is an issue-tracker that's serverless, distributed, and uses Git's built-in conflict resolution for field-level multiuser-capability.

It can reside in any project's own git repository, and multiple issue databases can be active at once.

<!-- TOC ignore:true -->
## Table of contents

<!-- TOC -->

- [Why](#why)
- [Features](#features)
- [Installing](#installing)
- [Developing](#developing)
- [Support NGDB Issue Tracker](#support-ngdb-issue-tracker)
- [Copyright and license](#copyright-and-license)

<!-- /TOC -->

## Why

There's a million software project issue management tools. But the typical approaches tend to target similar use-cases, leaving gaps for certain use-cases that this tool fills. No issue management tool is perfect for everything. (NGDB Issue Tracker is also not "perfect for everything".)

Examples:

- A markdown or other text-based backlog is fine until a project grows beyond proof-of-concept, and/or adds more developers. Then items need more advanced features like sorting and gouping by status and priority, nesting, gating, links to each other, change history, etc.

- Enterprise-class web-based issue tracking can be very robust (e.g. Jira). But for some projects it's either overkill, not even possible, or not a consideration. For example:

	- The project is very large and loose, and getting everyone signed up and committed to using it might be impossible. (E.g. Linux kernel.)

	- You have privacy/security/longevity concerns about your data living on someone else's server. (This would mostly be relevant if you are hosting your own private git repo for those reasons, and/or are using the encryption features of nano-git-db enterprise edition.)

- GitHub (et. al) Issues:

	- Perfect for their intended purpose: Allowing users to report issues. Beyond that, they're pretty useless. (But weren't intended to be more than that.)

	- They own your data, and you're tied down to one git host long-term.

## Features

- Issue fields follow a backlog item: type, status, priority or severity, what testing it needs, repro steps, cause, fix, branch, commit, test case, and signoff.

- Type, status, priority, and effort are pick lists, seeded from the schema.

- Child issues, recorded decisions, prereq and related links, comments for a progress log, an audit trail, and links to outside files.

- Named queries for open, waiting, critical and high, closed, and everything.

- The log is the database. It's append-only CSV that git merges by union, and the SQLite view is your own local cache built from it.

## Installing

There's no installer yet. It needs `ngdb` and `shcl` on the PATH, from [nano-git-db](https://github.com/yottacore/nano-git-db) and [shcl](https://github.com/yottacore/shcl).

## Developing

The files a deployment uses are the working files here:

| What    | File
| :---    | :---
| Config  | `source/config.shcl`
| Schema  | `source/ddl.shcl`, plus `source/ddl.queries.shcl` for named queries
| Tx-log  | `ngdb/issue-tracker_test/txlog.csv`
| View    | `~/.cache/ngdb/issue-tracker_test/local.sqlite`

A real deployment can keep these anywhere. `utility/ngdb-dev.bash` runs ngdb against the config and adds the database name to each command:

~~~bash
utility/ngdb-dev.bash --tui
utility/ngdb-dev.bash create issue ref=2026102508172800 title="First item" type=4 status=19
utility/ngdb-dev.bash query "SELECT ref, title FROM issue WHERE is_deleted = 0"
~~~

`cicd/cicd.bash` lints and tests, then commits and pushes. `--help` lists its flags. Lint and tests run in a docker image with shcl and ngdb built from pinned commits on their `dev` branches, and `cicd/bump-pins.bash` moves those pins. Without docker they run on your own PATH. Day to day work goes on `dev`, and `main` takes releases.

`git config core.hooksPath cicd/hooks` turns on the pre-push hook, which runs `cicd.bash --merge-gate` before a push to `main`, unless the push changes only docs.

## Support NGDB Issue Tracker

NGDB Issue Tracker is written and maintained in spare time. If it saves you time, these keep it going:

- [GitHub Sponsors](https://github.com/sponsors/jim-collier)

- [Ko-fi](https://ko-fi.com/jimcollier)

## Copyright and license

> Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]<br />
> Licensed under the [GNU Affero General Public License v3.0](license.md) (`AGPL-3.0-only`).<br />
> No warranty.<br />
> NGDB Issue Tracker™ is a [trademark](trademark.md) of Jim Collier.

The AGPL's network-use "SaaS" clause (what specifically differentiates it from regular GPL) is deliberate. If you run a modified `nano-git-db` as a network service - which anyone is free and encouraged to do - you must offer users your source so that others can continue to build on your work, and so on.
<!--
> Licensed under the [MIT License](https://mit-license.org/)<br />
> SPDX-License-Identifier: `MIT`.<br />
	- Most permissive and least protective

> Licensed under the [GNU General Public License v2.0](https://www.gnu.org/licenses/gpl-2.0.html).

> Licensed under the [GNU General Public License v2.0 or later](https://spdx.org/licenses/GPL-2.0-or-later.html).
> SPDX-License-Identifier: `GPL-2.0-or-later`<br />

> Licensed under the [GNU General Public License v3](https://www.gnu.org/licenses/gpl-3.0.en.html) license.

> Licensed under the [Mozilla Public License 2.0](https://mozilla.org/MPL/2.0/).

> Licensed under the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0.html)
> SPDX-License-Identifier: `Apache-2.0`<br />
	- Permissive
	- Patent protection clause
	- Requires attribution
	- No contribute back
	- SaaS loophole
-->
