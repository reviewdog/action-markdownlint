# GitHub Action: Run markdownlint with reviewdog

Based on [reviewdog/action-shellcheck](https://github.com/reviewdog/action-shellcheck)

[![Docker Image CI](https://github.com/prologic/action-markdownlint/workflows/Docker%20Image%20CI/badge.svg)](https://github.com/prologic/action-markdownlint/actions)
[![Release](https://img.shields.io/github/release/prologic/action-markdownlint.svg?maxAge=43200)](https://github.com/prologic/action-markdownlint/releases)

This action runs [markdownlint](https://github.com/DavidAnson/markdownlint) with
[reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to improve
code review experience.

## Inputs

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
  fail_on_error:
    description: |
      Exit code for reviewdog when errors are found [true,false]
      Default is `false`.
    default: 'false'
  reviewdog_flags:
    description: 'Additional reviewdog flags'
    default: ''
  ### Flags for markdownlint-cli ###
  markdownlint_flags:
    description: "Options of markdownlint-cli command. Default: '.'"
    default: '.'
```

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
      - uses: actions/checkout@v1
      - name: markdownlint
        uses: reviewdog/action-markdownlint@v0
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          reporter: github-pr-review
```
