#!/bin/sh
# Runs the test suite.  The migemo dictionary is not bundled with this
# repository, so point KENSHAKU_DICT at a migemo-compact-dict file.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

DICT=${KENSHAKU_DICT:-"$HOME/.cache/kensaku.vim/migemo-compact-dict"}
if [ ! -f "$DICT" ]; then
  echo "kensaku: dictionary not found: $DICT" >&2
  echo "Download it with:" >&2
  echo "  mkdir -p \"\$(dirname \"$DICT\")\"" >&2
  echo "  curl -fL -o \"$DICT\" https://github.com/oguna/migemo-compact-dict-latest/releases/download/v0.2/migemo-compact-dict" >&2
  exit 1
fi

mkdir -p test/actual
failed=0

run_vim() {
  log="test/actual/$1.log"
  shift
  if ! vim --clean \
      --cmd "set runtimepath+=$ROOT" \
      --cmd "let g:kensaku_dictionary_cache='$DICT'" \
      --cmd 'runtime! plugin/*.vim' \
      -es -V1 -S "$1" >"$log" 2>&1; then
    echo "FAIL: $1 (vim exited with an error)"
    cat "$log"
    failed=1
    return 0
  fi
  if grep -qE 'E[0-9]+:' "$log"; then
    echo "FAIL: $1 (vim error)"
    cat "$log"
    failed=1
  fi
}

check() {
  name=$1
  if ! diff -u "test/expected/$name.tsv" "test/actual/$name.tsv"; then
    echo "FAIL: $name"
    failed=1
    return 0
  fi
  echo "ok: $name"
}

run_vim query test/test_query.vim
run_vim romaji test/test_romaji.vim
run_vim charset test/test_charset.vim
run_vim search test/test_search.vim
run_vim rxop test/test_rxop.vim

check query
check romaji
check charset

check_text() {
  name=$1
  if [ "$(cat "test/actual/$name.txt")" != "ok" ]; then
    echo "FAIL: $name"
    cat "test/actual/$name.txt"
    failed=1
  else
    echo "ok: $name"
  fi
}

check_text search
check_text rxop

exit "$failed"
