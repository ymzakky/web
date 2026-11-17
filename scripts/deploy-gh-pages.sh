#!/usr/bin/env bash
#
# deploy-gh-pages.sh — Build the Astro site and publish it to the `gh-pages`
# branch (GitHub Pages). Intended for Claude / Linux / macOS environments.
#
# Windows deploys continue via the existing local workflow; this script is an
# equivalent alternative that produces the SAME gh-pages structure
# (full source tree + the built `dist/` contents flattened to the branch root).
#
# Usage:
#   ./scripts/deploy-gh-pages.sh [source-branch]   # default source-branch: main
#
# What it does:
#   1. Refreshes the source branch from origin (hard reset — no local edits kept)
#   2. npm install && npm run build
#   3. Assembles gh-pages content = source tree + dist/* flattened to root
#   4. Commits & pushes to the gh-pages branch (skips if nothing changed)
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SOURCE_BRANCH="${1:-main}"
DEPLOY_BRANCH="gh-pages"

echo "==> Deploying '${SOURCE_BRANCH}' -> '${DEPLOY_BRANCH}'"

# 0. Require a clean working tree so nothing is silently discarded.
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree is not clean. Commit or stash your changes first." >&2
  exit 1
fi

# 1. Get the latest source branch.
git fetch origin "$SOURCE_BRANCH"
git checkout "$SOURCE_BRANCH"
git reset --hard "origin/${SOURCE_BRANCH}"
SRC_SHA="$(git rev-parse --short HEAD)"

# 2. Install dependencies.
npm install

# 3. Build.
#    The Windows checkout pins tsconfig.json "extends" to a machine-specific
#    absolute path (e.g. "C:/.../astro/tsconfigs/strict.json"), which does not
#    resolve off that machine. If present, temporarily rewrite it to the
#    portable package path for the build, then restore the file so the source
#    branch stays byte-for-byte unchanged.
TSCONFIG_PATCHED=0
if grep -Eq '"extends"[[:space:]]*:[[:space:]]*"[A-Za-z]:' tsconfig.json 2>/dev/null; then
  cp tsconfig.json tsconfig.json.deploybak
  sed -i 's#"extends"[[:space:]]*:[[:space:]]*"[^"]*astro/tsconfigs/strict[^"]*"#"extends": "astro/tsconfigs/strict"#' tsconfig.json
  TSCONFIG_PATCHED=1
  echo "==> Temporarily patched tsconfig.json 'extends' for the build"
fi

npm run build

if [ "$TSCONFIG_PATCHED" = "1" ]; then
  mv tsconfig.json.deploybak tsconfig.json
  echo "==> Restored original tsconfig.json"
fi

# 4. Assemble the gh-pages payload in a temp dir:
#    the full source tree PLUS the built dist/ flattened to the root.
STAGE="$(mktemp -d)"
tar cf - --exclude=.git --exclude=node_modules . | ( cd "$STAGE" && tar xf - )
cp -a dist/. "$STAGE"/

# 5. Publish.
git fetch origin "$DEPLOY_BRANCH"
# -f discards the build's working-tree changes on the source branch before switching.
git checkout -f -B "$DEPLOY_BRANCH" "origin/${DEPLOY_BRANCH}"
git rm -rf . --quiet
cp -a "$STAGE"/. .
rm -rf "$STAGE"
git add -A

if git diff --cached --quiet; then
  echo "==> No changes to deploy. ${DEPLOY_BRANCH} is already up to date."
else
  git commit -m "ビルド成果物を更新（${SOURCE_BRANCH} ${SRC_SHA} を反映）"
  git push origin "$DEPLOY_BRANCH"
  echo "==> Deployed ${SOURCE_BRANCH} ${SRC_SHA} to ${DEPLOY_BRANCH}"
fi

# 6. Leave the checkout back on the source branch.
git checkout "$SOURCE_BRANCH"
echo "==> Done."
