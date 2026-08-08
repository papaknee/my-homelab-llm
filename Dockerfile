FROM ollama/ollama:latest

ENV OLLAMA_HOST=0.0.0.0:11434 \
    GENERAL_MODEL=qwen2.5:7b-instruct-q4_K_M \
    CODING_MODEL=deepseek-coder:16b-v2-lite-instruct-q4_K_M \
    OLLAMA_KEEP_ALIVE=5m

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 11434

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
