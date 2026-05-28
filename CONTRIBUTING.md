# Contributing

Thanks for your interest in improving this Seatsurfing patch fork.

This repository is maintained as a patch series on top of upstream
[seatsurfing/seatsurfing](https://github.com/seatsurfing/seatsurfing). Issues,
bug reports, and feature requests are welcome through GitHub Issues.

## Issues and Feature Requests

Open an issue for:

- bugs in the patched build,
- patch application problems,
- feature requests,
- questions about the maintained patch series.

Please include the upstream tag from `tags.txt`, the patch or feature involved,
and any relevant logs from `apply.sh` when reporting patch application issues.

## Pull Requests

Pull requests are welcome. Contributions can be submitted in either of these
forms:

- patch files added or updated under `server/`, `ui/`, or `i18n/`,
- a branch containing the patched repository changes directly.

Either form is fine. Before merge, changes will be normalized into patch files
in their respective categories:

- `server/` for backend and API changes,
- `ui/` for frontend code changes,
- `i18n/` for translation patch inputs.

Keep each change scoped to one category where possible. If a feature needs
backend, UI, and translation work, split it into separate commits or patch files
for each category.

## Patch Workflow

Patch files are generated with `git format-patch` and applied with `apply.sh`.
See [docs/patch-workflow.md](docs/patch-workflow.md) for the full workflow.

If the change touches code, also run the relevant project checks in the generated
checkout when possible.
