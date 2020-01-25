#!/bin/sh

cd "${GITHUB_WORKSPACE}" || exit

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

if [ "${INPUT_REPORTER}" = x"github-pr-review" ]; then
  markdownlint "${INPUT_MARKDOWNLINT_FLAGS:-.}" |
    reviewdog -efm="%s:%l %m" -name="markdownlint" -diff="git diff HEAD^" -reporter=github-pr-review -level="${INPUT_LEVEL}" -tee
else
  markdownlint "${INPUT_MARKDOWNLINT_FLAGS:-.}" |
    reviewdog -efm="%s:%l %m" -name="markdownlint" -diff="git diff HEAD^" -reporter=github-pr-check -level="${INPUT_LEVEL}" -tee
fi
