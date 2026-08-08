#!/usr/bin/env bash
set -euo pipefail

INTERVAL=5
MODE="both"
SERVICE="homelab-llm"

DEFAULT_GENERAL_MODEL="qwen2.5:7b-instruct-q4_K_M"
DEFAULT_CODING_MODEL="deepseek-coder-v2:16b-lite-instruct-q4_K_M"

GENERAL_MODEL=""
CODING_MODEL=""

usage() {
  cat <<'EOF'
Watch Ollama model download status every 5 seconds.

Usage:
  ./scripts/watch-model-download.sh [options]

Options:
  --mode one|both        Stop when one model is ready, or when both are ready (default: both)
  --interval SECONDS     Poll interval in seconds (default: 5)
  --service NAME         Compose service name (default: homelab-llm)
  --general-model NAME   Override general model name
  --coding-model NAME    Override coding model name
  -h, --help             Show this help text
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        MODE="$2"
        shift 2
        ;;
      --interval)
        INTERVAL="$2"
        shift 2
        ;;
      --service)
        SERVICE="$2"
        shift 2
        ;;
      --general-model)
        GENERAL_MODEL="$2"
        shift 2
        ;;
      --coding-model)
        CODING_MODEL="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

validate_args() {
  if [[ "$MODE" != "one" && "$MODE" != "both" ]]; then
    echo "Invalid --mode value: $MODE (use 'one' or 'both')" >&2
    exit 1
  fi

  if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [[ "$INTERVAL" -lt 1 ]]; then
    echo "--interval must be a positive integer" >&2
    exit 1
  fi
}

extract_env_from_container() {
  local key="$1"
  docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$SERVICE" 2>/dev/null \
    | awk -F= -v k="$key" '$1 == k { print $2; exit }'
}

resolve_models() {
  local gm cm

  gm="${GENERAL_MODEL}"
  cm="${CODING_MODEL}"

  if [[ -z "$gm" ]]; then
    gm="$(extract_env_from_container GENERAL_MODEL || true)"
  fi
  if [[ -z "$cm" ]]; then
    cm="$(extract_env_from_container CODING_MODEL || true)"
  fi

  GENERAL_MODEL="${gm:-$DEFAULT_GENERAL_MODEL}"
  CODING_MODEL="${cm:-$DEFAULT_CODING_MODEL}"
}

service_running() {
  docker compose ps --status running --services 2>/dev/null | grep -Fx "$SERVICE" >/dev/null 2>&1
}

model_ready() {
  local model_name="$1"
  docker compose exec -T "$SERVICE" ollama show "$model_name" >/dev/null 2>&1
}

main() {
  parse_args "$@"
  validate_args

  resolve_models

  echo "Watching model status every ${INTERVAL}s (mode=${MODE}, service=${SERVICE})"
  echo "General model: ${GENERAL_MODEL}"
  echo "Coding model:  ${CODING_MODEL}"
  echo

  while true; do
    local ts general_state coding_state
    ts="$(date '+%Y-%m-%d %H:%M:%S')"

    if ! service_running; then
      echo "[$ts] Service '${SERVICE}' is not running yet. Waiting..."
      sleep "$INTERVAL"
      continue
    fi

    if model_ready "$GENERAL_MODEL"; then
      general_state="ready"
    else
      general_state="downloading"
    fi

    if model_ready "$CODING_MODEL"; then
      coding_state="ready"
    else
      coding_state="downloading"
    fi

    echo "[$ts] general=${general_state} coding=${coding_state}"

    if [[ "$MODE" == "one" ]]; then
      if [[ "$general_state" == "ready" || "$coding_state" == "ready" ]]; then
        echo "Done: at least one model is ready."
        exit 0
      fi
    else
      if [[ "$general_state" == "ready" && "$coding_state" == "ready" ]]; then
        echo "Done: both models are ready."
        exit 0
      fi
    fi

    sleep "$INTERVAL"
  done
}

main "$@"
