#!/bin/sh

cd "${GITHUB_WORKSPACE}" || exit

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

markdownlint "${INPUT_MARKDOWNLINT_FLAGS:-.}" |
  reviewdog -efm="%f:%l:%c %m" -efm="%f:%l %m" -name="markdownlint" -reporter="${INPUT_REPORTER}" -level="${INPUT_LEVEL}"
