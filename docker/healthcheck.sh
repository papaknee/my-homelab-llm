#!/bin/sh
set -eu

ollama list >/dev/null 2>&1

check_model() {
  model_name="$1"
  if [ -n "$model_name" ]; then
    ollama show "$model_name" >/dev/null 2>&1
  fi
}

check_model "${GENERAL_MODEL:-}"
check_model "${CODING_MODEL:-}"
