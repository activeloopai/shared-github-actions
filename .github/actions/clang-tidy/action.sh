#!/usr/bin/env bash

set -e

trap 'rm -rf ${TEMP_DIR}' EXIT

function log() {
  local level ts
  level="$1"
  ts="$(date --utc -Iseconds)"
  shift
  printf "[%s] - [%s] - \"%s\"\n" "${level^^}" "${ts}" "$*"
}

function run_tidy() {
  local output file_warnings file_errors
  output=$(clang-tidy --header-filter=".*${PROJECT_NAME}.*" -p "$BUILD_DIR" "$1" 2>&1 || true)
  file_warnings=$(echo "$output" | grep -c "${FILENAMES_BASE}/.*warning:" || true)
  file_errors=$(echo "$output" | grep -c "${FILENAMES_BASE}/.*error:" || true)
  echo "$file|$file_warnings|$file_errors" >"${TEMP_DIR}/${1}.count"
  if [ "$file_errors" -gt 0 ]; then
    echo "$output" | grep "${FILENAMES_BASE}/.*error:" >"${TEMP_DIR}/${1}.output"
  elif [ "$file_warnings" -gt 0 ]; then
    echo "$output" | grep "${FILENAMES_BASE}/.*warning:" >"${TEMP_DIR}/${1}.output"
  fi
}

SOURCE_DIR="$(realpath "$1")"
BUILD_DIR="$(realpath "$2")"
PROJECT_NAME="${SOURCE_DIR##*/}"
TEMP_DIR="$(mktemp -d)"

log info "source directory: ${SOURCE_DIR}"
log info "build directory: ${BUILD_DIR}"

if [ ! -f "${BUILD_DIR}/compile_commands.json" ]; then
  log error "${BUILD_DIR}/compile_commands.json not found , please build the project first to generate compile_commands.json"
  exit 1
fi

cd "${SOURCE_DIR}"
if ! (clang-tidy --version); then
  log error "clang-tidy not installed"
  exit 1
fi

log info "running clang-tidy, build=${BUILD_DIR} source=${SOURCE_DIR}"

WORKER_COUNT="$(nproc)"
for file in *.cpp; do
  run_tidy "${file}" &
  while [ "$(jobs | wc -l)" -ge "${WORKER_COUNT}" ]; do
    sleep 0.1
  done
done
wait

log info "processing results"

WARNINGS=0
ERRORS=0

for file in *.cpp; do
  if [ -f "${TEMP_DIR}/${file}.count" ]; then
    IFS='|' read -r _ FILE_WARNINGS FILE_ERRORS <"${TEMP_DIR}/${file}.count"
    if [ "$FILE_ERRORS" -gt 0 ]; then
      log error "$file - has $FILE_ERRORS errors"
      cat "${TEMP_DIR}/${file}.output"
      ERRORS=$((ERRORS + FILE_ERRORS))
    elif [ "$FILE_WARNINGS" -gt 0 ]; then
      log warn "$file - has $FILE_WARNINGS warnings"
      cat "${TEMP_DIR}/${file}.output"
      WARNINGS=$((WARNINGS + FILE_WARNINGS))
    else
      log info "$file - no issues"
    fi
  fi
done

log info "clang-tidy summary: warnings=$WARNINGS errors=$ERRORS"

if [ $ERRORS -gt 0 ]; then
  log error "clang-tidy found $ERRORS errors"
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  log warn "clang-tidy found $WARNINGS warnings (non-blocking)"
  exit 0
else
  log info "no issues found"
  exit 0
fi
