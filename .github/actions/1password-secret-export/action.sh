#!/bin/bash

set -eE -o pipefail -o functrace

trap 'error_handler $LINENO' ERR

error_handler() {
    local line_number=$1
    echo "Error Details:"
    echo "  Line: $line_number"
    echo "  Command: $BASH_COMMAND"
    exit 1
}

setup() {

  : "${OP_VAULT:?OP_VAULT is required}"
  : "${OP_ITEM:?OP_ITEM is required}"
  : "${OP_SERVICE_ACCOUNT_TOKEN:?OP_SERVICE_ACCOUNT_TOKEN is required}"
  : "${OP_SECTIONS:-''}"
  : "${EXPORT_VARIABLES:-true}"
  : "${EXPORT_TO_FILE:-false}"

  declare -gA ALLOWED_CATEGORIES

  ALLOWED_CATEGORIES=(
    ["SECURE_NOTE"]=1
  )
}

check() {
  local category
  category="$(op item get --vault "${OP_VAULT}" "${OP_ITEM}" --format=json | yq -r '.category')"
  if [ "${ALLOWED_CATEGORIES[${category}]}" != "1" ]; then
    echo "category \`${category}\` is not allowed"
    exit 1
  fi
}

merge() {
  local result
  result='{}'
  for i in "$@"; do
    result="$(yq -o json "$result * ." < <(printf "%s" "$i"))"
  done
  echo "$result"
}

from_sections() {
  local sections value result
  readarray -t sections < <(printf "%s" "${OP_SECTIONS}")
  result='{}'
  for section in "${sections[@]}"; do
    export OP_SECTION_NAME="$section"
    # shellcheck disable=SC2016
    value="$(op item get --vault "${OP_VAULT}" "${OP_ITEM}" --format=json | yq -o json '.fields[] | select(.section.label == env(OP_SECTION_NAME) and .label != "notesPlain") | {.label: .value} | . as $item ireduce ({}; . * $item )')"
    result="$(merge "$result" "$value")"
  done
}

from_root() {
  # shellcheck disable=SC2016
  op item get --vault "${OP_VAULT}" "${OP_ITEM}" --format=json | yq -o json '.fields[] | select(.section.id == "add more" and .label != "notesPlain") | {.label: .value} | . as $item ireduce ({}; . * $item )'
}

main() {
  local from_root from_sections result
  from_root="$(from_root)"
  from_sections="$(from_sections)"
  from_sections="${from_sections:-{}}"
    result="$(merge "${from_root}" "${from_sections}")"
  if [ "${EXPORT_VARIABLES}" == "true" ]; then
    yq . -o shell < <(printf "%s" "${result}") >>"${GITHUB_ENV}"
  fi
  if [ "${EXPORT_TO_FILE}" == "true" ]; then
    yq . -o shell < <(printf "%s" "${result}") >>.env
  fi
}

setup
check
main
