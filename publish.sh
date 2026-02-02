#!/bin/bash
set -e

REPO_URL="$1"
BRANCH="${2:-main}"

if ! command -v git &> /dev/null; then
    echo "未找到 git"
    exit 1
fi

if [ -z "$REPO_URL" ]; then
    echo "用法: bash publish.sh <repo_url> [branch]"
    exit 1
fi

if [ ! -d ".git" ]; then
    git init
fi

git add -A

if ! git diff --cached --quiet; then
    git commit -m "init"
fi

git branch -M "$BRANCH"

if git remote | grep -q "^origin$"; then
    git remote set-url origin "$REPO_URL"
else
    git remote add origin "$REPO_URL"
fi

git push -u origin "$BRANCH"
