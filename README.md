# GitHub Action: Run markdownlint with reviewdog

Based on [reviewdog/action-shellcheck](https://github.com/reviewdog/action-shellcheck)

[![Docker Image CI](https://github.com/prologic/action-markdownlint/workflows/Docker%20Image%20CI/badge.svg)](https://github.com/prologic/action-markdownlint/actions)
[![Release](https://img.shields.io/github/release/prologic/action-markdownlint.svg?maxAge=43200)](https://github.com/prologic/action-markdownlint/releases)

This action runs [markdownlint](https://github.com/DavidAnson/markdownlint) with
[reviewdog](https://github.com/reviewdog/reviewdog) on pull requests to improve
code review experience.

## Inputs

### `github_token`

**Required**. Must be in form of `github_token: ${{ secrets.github_token }}`'.

### `level`

Optional. Report level for reviewdog [info,warning,error].
It's same as `-level` flag of reviewdog.

### `reporter`

Reporter of reviewdog command [github-pr-check,github-pr-review,github-check].
Default is github-pr-check.
github-pr-review can use Markdown and add a link to rule page in reviewdog reports.

### `markdownlint_flags`

Optional. Flags of markdownlint command. Default: `.`

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
        uses: prologic/action-markdownlint@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          reporter: github-pr-review # Change reporter. (Only `github-pr-check` is supported at the moment).
```
