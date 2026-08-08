#!/bin/sh
set -eu

ollama serve &
server_pid="$!"

cleanup() {
  kill "$server_pid" 2>/dev/null || true
}

trap cleanup INT TERM EXIT

wait_for_server() {
  attempt=0
  until ollama list >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 60 ]; then
      echo "Ollama server did not become ready in time."
      exit 1
    fi
    sleep 2
  done
}

model_exists() {
  ollama show "$1" >/dev/null 2>&1
}

pull_with_retries() {
  model_name="$1"
  max_attempts="${MODEL_PULL_RETRIES:-3}"
  attempt=1

  while [ "$attempt" -le "$max_attempts" ]; do
    echo "Pulling model ($attempt/$max_attempts): $model_name"
    if ollama pull "$model_name"; then
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 2
  done

  echo "Failed to pull model after $max_attempts attempt(s): $model_name"
  return 1
}

pull_model() {
  model_name="$1"
  if [ -z "$model_name" ]; then
    return 0
  fi

  if model_exists "$model_name"; then
    echo "Model already available: $model_name"
    return 0
  fi

  if [ "${PULL_MISSING_MODELS:-true}" != "true" ]; then
    echo "Model not present and auto-pull disabled: $model_name"
    return 0
  fi

  if ! pull_with_retries "$model_name"; then
    echo "WARNING: continuing startup without model: $model_name"
    echo "The container will stay up but report unhealthy until the model exists."
    return 0
  fi
}

wait_for_server
pull_model "$GENERAL_MODEL"
pull_model "$CODING_MODEL"

wait "$server_pid"
