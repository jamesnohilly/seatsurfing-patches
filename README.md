# Seatsurfing Patch Fork

This repository is a fork of [Seatsurfing](https://github.com/seatsurfing/seatsurfing) that carries a maintained patch series for upstream releases.

## Overview

The fork is organized as a patch set applied on top of an upstream Seatsurfing tag. The current patch series is maintained against `v1.99.0`.

The repository contains:

- `server/` for backend changes
- `i18n/` for translation file updates
- `ui/` for frontend code changes
- `docs/` for workflow and maintenance notes

## Added Features

This fork adds sub-group hierarchy and group-management enhancements on top of upstream Seatsurfing.

## Documentation

Workflow and patch maintenance notes live in [docs/](docs/README.md).

## Quick Reference

- **Upstream:** [seatsurfing/seatsurfing](https://github.com/seatsurfing/seatsurfing)
- **Base tag:** `v1.99.0`
- **License:** [GPL 3.0](LICENSE)

## Patch Application

Use the installer in [apply.sh](apply.sh) to clone the selected upstream tag and apply the patch series.

```bash
./apply.sh -m tags.txt -e development
```

## Status

This repository tracks a curated forked patch series. It is not the upstream Seatsurfing project.
