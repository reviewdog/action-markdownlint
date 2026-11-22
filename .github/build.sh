#!/usr/bin/env bash

set -uex -o pipefail
shopt -s inherit_errexit

# Set up variables.
TAG="${INPUT_TAG:-${GITHUB_REF#refs/tags/}}" # v1.2.3
MINOR="${TAG%.*}"                            # v1.2
MAJOR="${MINOR%.*}"                          # v1
IMAGE="ghcr.io/$GITHUB_REPOSITORY:$TAG"

# Login to GHCR
printenv GITHUB_TOKEN | docker login ghcr.io --username "${GITHUB_REPOSITORY%/*}" --password-stdin

# Build Docker Image
# Build and push multi-platform image
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag "$IMAGE" \
    --push \
    .
DIGEST=$(docker buildx imagetools inspect "$IMAGE" --format "{{json .Manifest}}" | jq -r '.digest')
docker logout ghcr.io

# Set up Git.
# Commits are created locally only to compute their trees.
# They are re-created through the GitHub API so that GitHub signs them,
# and branches/tags are updated through the API instead of `git push`.
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# local commit SHA => SHA of the signed commit created on GitHub
declare -A REMOTE_COMMIT=()

api() {
    gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2026-03-10" "$@"
}

# upload_tree BASE_TREE TREE
# Creates TREE on GitHub by applying its differences from BASE_TREE, which must already exist on GitHub.
upload_tree() {
    local base_tree="$1" tree="$2" entries meta path old_mode new_mode new_sha status type sha remote_tree
    entries=$(mktemp)
    while IFS= read -r -d '' meta && IFS= read -r -d '' path; do
        read -r old_mode new_mode _ new_sha status <<<"${meta#:}"
        if [[ "$status" == D ]]; then
            if [[ "$old_mode" == 160000 ]]; then type=commit; else type=blob; fi
            jq -nc --arg path "$path" --arg mode "$old_mode" --arg type "$type" \
                '{path: $path, mode: $mode, type: $type, sha: null}'
            continue
        fi
        if [[ "$new_mode" == 160000 ]]; then
            type=commit
            sha="$new_sha"
        else
            type=blob
            sha=$(git cat-file blob "$new_sha" | base64 | tr -d '\n' |
                jq -Rs '{content: ., encoding: "base64"}' |
                api --method POST "repos/$GITHUB_REPOSITORY/git/blobs" --input - --jq .sha)
            if [[ "$sha" != "$new_sha" ]]; then
                echo "blob mismatch for $path: expected $new_sha, got $sha" >&2
                return 1
            fi
        fi
        jq -nc --arg path "$path" --arg mode "$new_mode" --arg type "$type" --arg sha "$sha" \
            '{path: $path, mode: $mode, type: $type, sha: $sha}'
    done < <(git diff-tree -r -z --no-renames "$base_tree" "$tree") >"$entries"

    if [[ ! -s "$entries" ]]; then
        rm -f "$entries"
        echo "$base_tree"
        return
    fi
    remote_tree=$(jq -s --arg base_tree "$base_tree" '{base_tree: $base_tree, tree: .}' "$entries" |
        api --method POST "repos/$GITHUB_REPOSITORY/git/trees" --input - --jq .sha)
    rm -f "$entries"
    if [[ "$remote_tree" != "$tree" ]]; then
        echo "tree mismatch: expected $tree, got $remote_tree" >&2
        return 1
    fi
    echo "$remote_tree"
}

# publish_commit COMMIT
# Re-creates the local COMMIT on GitHub as a commit signed by GitHub, and prints its SHA.
# The parents of COMMIT must already exist on GitHub (or be published by publish_commit).
publish_commit() {
    local commit="$1" parent parents=() tree result sha verified
    for parent in $(git show -s --format=%P "$commit"); do
        parents+=("${REMOTE_COMMIT[$parent]:-$parent}")
    done
    tree=$(upload_tree "$(git rev-parse "$commit^1^{tree}")" "$(git rev-parse "$commit^{tree}")")

    # Do not set author and committer. GitHub signs the commit only if they are omitted.
    result=$(git show -s --format=%B "$commit" |
        jq -Rs --arg tree "$tree" '{message: ., tree: $tree, parents: $ARGS.positional}' --args "${parents[@]}" |
        api --method POST "repos/$GITHUB_REPOSITORY/git/commits" --input - --jq '[.sha, .verification.verified] | @tsv')
    read -r sha verified <<<"$result"
    if [[ "$verified" != true ]]; then
        echo "::warning::commit $sha is not signed" >&2
    fi
    echo "$sha"
}

# remote_commit REV
# Prints the SHA of the commit on GitHub that corresponds to the local REV.
remote_commit() {
    local commit
    commit=$(git rev-parse "$1^{commit}")
    echo "${REMOTE_COMMIT[$commit]:-$commit}"
}

# update_ref REF SHA FORCE
# Creates or updates REF (e.g. heads/master, tags/v1) on GitHub.
update_ref() {
    local ref="$1" sha="$2" force="$3"
    if api "repos/$GITHUB_REPOSITORY/git/ref/$ref" --silent >/dev/null 2>&1; then
        api --method PATCH "repos/$GITHUB_REPOSITORY/git/refs/$ref" -f sha="$sha" -F force="$force" --silent
    else
        api --method POST "repos/$GITHUB_REPOSITORY/git/refs" -f ref="refs/$ref" -f sha="$sha" --silent
    fi
}

# publish_branch BRANCH
# Publishes the local commits on BRANCH that are not on GitHub yet, and updates BRANCH on GitHub.
publish_branch() {
    local branch="$1" commit published=false
    while read -r commit; do
        if [[ -z "${REMOTE_COMMIT[$commit]:-}" ]]; then
            REMOTE_COMMIT[$commit]=$(publish_commit "$commit")
            published=true
        fi
    done < <(git rev-list --reverse --topo-order "refs/heads/$branch" --not --remotes=origin)
    if [[ "$published" == true ]]; then
        update_ref "heads/$branch" "$(remote_commit "refs/heads/$branch")" false
    fi
}

# update the major version if major version is bumped
echo "$MAJOR" > .major-version
git add .major-version
git commit -m "bump $MAJOR" || true
publish_branch "$CURRENT_BRANCH"

# checkout releases branch
git branch -D "releases/$MAJOR" || true
git checkout -b "releases/$MAJOR" "origin/releases/$MAJOR" || git checkout -b "releases/$MAJOR" "$CURRENT_BRANCH"
git merge -X theirs --no-ff -m "Merge branch '$CURRENT_BRANCH' into releases/$MAJOR" "$CURRENT_BRANCH" || true

# configure to use the pre-built image
git checkout "$CURRENT_BRANCH" -- action.yml
perl -i -pe "s(image:\\s*[\"']?Dockerfile[\"']?)(image: 'docker://ghcr.io/$GITHUB_REPOSITORY:$TAG\\@$DIGEST')" action.yml
git add action.yml
git commit -m "bump $TAG"
publish_branch "releases/$MAJOR"
RELEASE_COMMIT=$(remote_commit HEAD)

# Create the release tag, and update MAJOR/MINOR tags.
# These are lightweight tags pointing to the signed commit,
# because GitHub doesn't sign annotated tag objects created through the API.
api --method POST "repos/$GITHUB_REPOSITORY/git/refs" -f ref="refs/tags/$TAG" -f sha="$RELEASE_COMMIT" --silent
update_ref "tags/$MINOR" "$RELEASE_COMMIT" true
update_ref "tags/$MAJOR" "$RELEASE_COMMIT" true
