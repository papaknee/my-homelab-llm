FROM ollama/ollama@sha256:b88c73ace3e115f8ec53dc8761ae1c0aabfa675406e3681786b98757ce050f42

ENV OLLAMA_HOST=0.0.0.0:11434 \
    GENERAL_MODEL=qwen2.5:7b-instruct-q4_K_M \
    CODING_MODEL=deepseek-coder-v2:16b-lite-instruct-q4_K_M \
    OLLAMA_KEEP_ALIVE=5m \
    OLLAMA_MAX_LOADED_MODELS=1 \
    PULL_MISSING_MODELS=true \
    MODEL_PULL_RETRIES=3

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

EXPOSE 11434

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD /usr/local/bin/healthcheck.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
