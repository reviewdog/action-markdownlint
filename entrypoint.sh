#!/bin/sh

cd "${GITHUB_WORKSPACE}" || exit

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# shellcheck disable=SC2086
markdownlint "${INPUT_MARKDOWNLINT_FLAGS:-.}" 2>&1 \
  | reviewdog \
      -efm="%f:%l:%c %m" \
      -efm="%f:%l %m" \
      -name="markdownlint" \
      -reporter="${INPUT_REPORTER:-github-pr-check}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS} || EXIT_CODE=$?

 # github-pr-review only diff adding
if [ "${INPUT_REPORTER}" = "github-pr-review" ]; then
  # fix
  markdownlint --fix "${INPUT_MARKDOWNLINT_FLAGS:-.}" 2>&1 || true

  TMPFILE=$(mktemp)
  git diff > "${TMPFILE}"

  git stash -u

  # shellcheck disable=SC2086
  reviewdog                        \
    -f=diff                        \
    -f.diff.strip=1                \
    -name="markdownlint-fix"       \
    -reporter="github-pr-review"   \
    -filter-mode="diff_context"    \
    -level="${INPUT_LEVEL}"        \
    ${INPUT_REVIEWDOG_FLAGS} < "${TMPFILE}"

  git stash drop || true
fi

exit ${EXIT_CODE}
