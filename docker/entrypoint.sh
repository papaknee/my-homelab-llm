#!/bin/sh
set -eu

ollama serve &
server_pid="$!"

cleanup() {
  kill "$server_pid" 2>/dev/null || true
}

trap cleanup INT TERM EXIT

attempt=0
until ollama list >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 60 ]; then
    echo "Ollama server did not become ready in time."
    exit 1
  fi
  sleep 2
done

pull_model() {
  model_name="$1"
  if [ -n "$model_name" ]; then
    echo "Ensuring model is available: $model_name"
    ollama pull "$model_name"
  fi
}

pull_model "$GENERAL_MODEL"
pull_model "$CODING_MODEL"

wait "$server_pid"
