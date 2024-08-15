# ResearchCloud Components for Windows workspaces

This repository contains [PowerShell](microsoft.com/PowerShell) installation scripts for use in conjunction with [SURF ResearchCloud](https://portal.live.surfresearchcloud.nl). ResearchCloud catalog maintainers can configure a playbook from this repo as a script source for a component.

There is a separate repository containting the UU installation scripts for Unix/Linux workspaces: https://github.com/UtrechtUniversity/researchcloud-items/

See [here](https://utrechtuniversity.github.io/vre-docs/) for user documentation and an introduction to ResearchCloud.

See [here](https://utrechtuniversity.github.io/researchcloud-items/) for general developer documentation (mostly focused on Linux workspaces).

## Repository layout

The `docs` directory contains documentation for the installation scripts in the `scripts` directory.

`scripts/lib` is a set of general scripts containing functions that can be included in each scripts. Documentation for these is inline.

## CI

Currently we are only running the [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) linter in CI.

A Dockerfile is provided for running PSScriptAnalyzer locally. To use it:

```
docker build . -t psscriptanalyzer
docker run --rm -v $(pwd):/src -it psscriptanalyzer # from the directory containing your scripts
```
