# GitHub Action: Run markdownlint with reviewdog

Based on [reviewdog/action-shellcheck](https://github.com/reviewdog/action-shellcheck)

[![Docker Image CI](https://github.com/prologic/action-markdownlint/workflows/Docker%20Image%20CI/badge.svg)](https://github.com/prologic/action-markdownlint/actions)
[![Release](https://img.shields.io/github/release/prologic/action-markdownlint.svg?maxAge=43200)](https://github.com/prologic/action-markdownlint/releases)

This action runs [markdownlint](https://github.com/DavidAnson/markdownlint) with
[reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to improve
code review experience.

## Inputs

<!-- markdownlint-disable MD013 -->
```yml
inputs:
  github_token:
    description: 'GITHUB_TOKEN.'
    default: '${{ github.token }}'
  ### Flags for reviewdog ###
  level:
    description: 'Report level for reviewdog [info,warning,error]'
    default: 'error'
  reporter:
    description: 'Reporter of reviewdog command [github-check,github-pr-review].'
    default: 'github-check'
  filter_mode:
    description: |
      Filtering mode for the reviewdog command [added,diff_context,file,nofilter].
      Default is added.
    default: 'added'
  fail_level:
    description: |
      If set to `none`, always use exit code 0 for reviewdog.
      Otherwise, exit code 1 for reviewdog if it finds at least 1 issue with severity greater than or equal to the given level.
      Possible values: [none,any,info,warning,error]
      Default is `none`.
    default: 'none'
  fail_on_error:
    description: |
      Deprecated, use `fail_level` instead.
      Exit code for reviewdog when errors are found [true,false]
      Default is `false`.
    deprecationMessage: Deprecated, use `fail_level` instead.
    default: 'false'
  reviewdog_flags:
    description: 'Additional reviewdog flags'
    default: ''
  ### Flags for markdownlint-cli ###
  markdownlint_flags:
    description: "Options of markdownlint-cli command. Default: '.'"
    default: '.'
```
<!-- markdownlint-enable MD013 -->

## Example usage

### [.github/workflows/reviewdog.yml](.github/workflows/reviewdog.yml)

```yml
name: reviewdog
on: [pull_request]
jobs:
  markdownlint:
    name: runner / markdownlint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
      - name: markdownlint
        uses: reviewdog/action-markdownlint@3667398db9118d7e78f7a63d10e26ce454ba5f58 # v0.26.2
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          reporter: github-pr-review
```
