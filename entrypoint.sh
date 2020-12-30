#!/bin/sh

cd "${GITHUB_WORKSPACE}" || exit

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

markdownlint "${INPUT_MARKDOWNLINT_FLAGS:-.}" 2>&1 |
  reviewdog \
      -efm="%f:%l:%c %m" \
      -efm="%f:%l %m" \
      -name="markdownlint" \
      -reporter="${INPUT_REPORTER:-github-pr-check}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}
