#!/usr/bin/env bash

set -euo pipefail

FILE="${1:-output/figma-capture/index.html}"

assert_contains() {
  local pattern="$1"
  if ! rg -q "$pattern" "$FILE"; then
    echo "Missing expected pattern: $pattern" >&2
    exit 1
  fi
}

assert_not_contains() {
  local pattern="$1"
  if rg -q "$pattern" "$FILE"; then
    echo "Unexpected pattern present: $pattern" >&2
    exit 1
  fi
}

assert_contains 'class="status-bar"'
assert_contains 'class="top-actions"'
assert_contains 'class="coach-card"'
assert_contains 'class="library-switcher"'
assert_contains 'class="course-rail"'
assert_contains 'class="article-card"'
assert_contains 'class="bottom-nav"'
assert_contains 'aria-label="Top Actions"'
assert_contains 'aria-label="Coach Hero Card"'
assert_contains 'aria-label="Course Carousel"'
assert_contains 'aria-label="Bottom Navigation"'
assert_contains '地道口语1000句'
assert_contains '雅思阅读高频话题30篇'
assert_contains '查单词或搜索文章'
assert_not_contains '<main class="frame">[[:space:]]*<img'

echo "Figma capture structure check passed for $FILE"
