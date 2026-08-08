# my-homelab-llm

Simple Docker-based setup for running a LAN-accessible Ollama node for:

- Home Assistant AI
- VS Code coding assistants
- General local chat and automation

By default, this project downloads and keeps available these two Ollama models:

- General assistant/chatbot: `qwen2.5:7b-instruct-q4_K_M`
- Coding assistant: `deepseek-coder:16b-v2-lite-instruct-q4_K_M`

Ollama automatically loads and unloads models as requests change, so the coding model and Home Assistant/chat model can share the same machine without both staying in VRAM all the time.

## What this repo gives you

- A Docker image that starts `ollama serve`
- LAN access on port `11434`
- Automatic first-run download of the two default models
- Persistent model storage in a Docker volume
- Optional NVIDIA GPU/CUDA enablement

---

## 1. Before you start

You need:

- A computer on your home network that will stay on
- Docker Desktop **or** Docker Engine + Docker Compose
- At least:
  - ~20 GB free disk space for models and room to grow
  - 16 GB+ system RAM recommended
  - NVIDIA GPU strongly recommended for the coding model

### Recommended hardware

- **Good CPU-only experience:** general chat, light Home Assistant use
- **Good GPU experience:** Home Assistant + coding assistant with faster responses
- **Recommended NVIDIA VRAM:** 12 GB minimum, 16 GB+ preferred

---

## 2. Files in this repo

- `Dockerfile` - builds the Ollama container
- `docker-compose.yml` - normal setup
- `docker-compose.gpu.yml` - optional NVIDIA GPU override
- `docker/entrypoint.sh` - starts Ollama and downloads the default models

---

## 3. Quick start (non-technical)

Open a terminal in this folder and run:

```bash
docker compose up -d --build
```

On first start, the container will:

1. Start Ollama
2. Download:
   - `qwen2.5:7b-instruct-q4_K_M`
   - `deepseek-coder:16b-v2-lite-instruct-q4_K_M`
3. Keep running on port `11434`

### Check that it is running

```bash
docker compose logs -f
```

Wait until you see model pull completion messages.

Then test locally:

```bash
curl http://localhost:11434/api/tags
```

You should see both models listed.

---

## 4. Find the IP address for other devices on your LAN

Other computers on your network should connect to:

```text
http://YOUR-COMPUTER-IP:11434
```

Examples:

- `http://192.168.1.50:11434`
- `http://10.0.0.25:11434`

If you are unsure of your IP address:

- **Windows:** run `ipconfig`
- **macOS/Linux:** run `ip addr` or `ifconfig`

Make sure your firewall allows inbound TCP traffic on port `11434`.

---

## 5. Enable NVIDIA GPU / CUDA

If your host has an NVIDIA GPU, install:

1. Latest NVIDIA driver
2. Docker
3. NVIDIA Container Toolkit

Official NVIDIA Container Toolkit docs:

https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

### After that, start with the GPU override

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d --build
```

### Verify GPU access

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml exec homelab-llm ollama ps
```

If GPU is enabled correctly, Ollama should use the GPU automatically when the model and system support it.

### Important note

If you do **not** have an NVIDIA GPU, use only:

```bash
docker compose up -d --build
```

---

## 6. Home Assistant setup

Home Assistant can use Ollama over your LAN.

### In Home Assistant

1. Open **Settings**
2. Open **Devices & Services**
3. Click **Add Integration**
4. Search for **Ollama**
5. Enter your server URL:

```text
http://YOUR-COMPUTER-IP:11434
```

### Recommended model for Home Assistant

Use:

```text
qwen2.5:7b-instruct-q4_K_M
```

This is the better default for:

- general chat
- tool-driven assistant behavior
- Home Assistant voice or text interactions

### Home Assistant tip

If you want Home Assistant isolated from coding usage, keep Home Assistant configured to only use the Qwen model and point coding tools to the DeepSeek model.

---

## 7. VS Code setup

Any VS Code extension that supports Ollama or an OpenAI-compatible local endpoint can use this server.

Popular options include:

- Continue
- Cline
- Roo Code
- Other agent/coding extensions with Ollama support

### Ollama base URL

Use:

```text
http://YOUR-COMPUTER-IP:11434
```

### Recommended coding model

Use:

```text
deepseek-coder:16b-v2-lite-instruct-q4_K_M
```

### Recommended chat model

Use:

```text
qwen2.5:7b-instruct-q4_K_M
```

### Example Continue configuration

```json
{
  "models": [
    {
      "title": "Homelab Chat",
      "provider": "ollama",
      "model": "qwen2.5:7b-instruct-q4_K_M",
      "apiBase": "http://YOUR-COMPUTER-IP:11434"
    },
    {
      "title": "Homelab Code",
      "provider": "ollama",
      "model": "deepseek-coder:16b-v2-lite-instruct-q4_K_M",
      "apiBase": "http://YOUR-COMPUTER-IP:11434"
    }
  ]
}
```

If your extension supports separate chat and autocomplete/code models, assign:

- chat/general assistant -> Qwen
- code generation/agent -> DeepSeek Coder

---

## 8. Common commands

### Start

```bash
docker compose up -d
```

### Stop

```bash
docker compose down
```

### Watch logs

```bash
docker compose logs -f
```

### List installed models

```bash
docker compose exec homelab-llm ollama list
```

### Pull an extra model later

```bash
docker compose exec homelab-llm ollama pull llama3.1:8b
```

This makes the setup broadly extensible for future Home Assistant or coding workflows.

---

## 9. Changing the default models

You can override either default model at startup:

```bash
GENERAL_MODEL=your-model CODING_MODEL=your-coding-model docker compose up -d --build
```

Example:

```bash
GENERAL_MODEL=qwen2.5:14b CODING_MODEL=deepseek-coder:33b docker compose up -d --build
```

---

## 10. Troubleshooting

### The first start takes a long time

That is normal. The models are several gigabytes each.

### Another device cannot connect

Check:

- the server computer is powered on
- Docker container is running
- port `11434` is open in the firewall
- you used the correct LAN IP address

### The coding model feels slow

That usually means:

- CPU-only mode is being used
- there is not enough GPU VRAM
- the host does not have enough RAM

### I want to reset everything

```bash
docker compose down -v
```

Then start again:

```bash
docker compose up -d --build
```
