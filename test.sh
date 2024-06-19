#!/usr/bin/env bash

STATE_FILE='.state'

function step_executed() {
  if [[ $# == 0 ]]; then return 1; fi

  if ! grep -Eq "^$@$" "$STATE_FILE" 2>&1 >/dev/null; then
    return 1
  else
    return 0
  fi
}

function mark_step_as_executed() {
  echo "$@" >> "$STATE_FILE"
}

function main() {
  if [[ -z "$MAIN_USER" ]] && ! step_executed "create_main_user" 2>&1 >/dev/null; then
    echo "Yes"
  else
    echo "No"
  fi
}

main "$@"
