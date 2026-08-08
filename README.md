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

### Check container health

```bash
docker ps
```

After startup finishes, the container status should show `healthy`.

You can also inspect health details directly:

```bash
docker inspect --format='{{json .State.Health}}' homelab-llm
```

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

## 6. Make it start automatically when your computer starts

This repo already sets:

```yaml
restart: unless-stopped
```

That means the container will come back automatically after Docker itself starts.

### Windows

1. Open **Docker Desktop**
2. Go to **Settings**
3. Enable **Start Docker Desktop when you log in**
4. Start the container once:

```bash
docker compose up -d
```

After that, Docker Desktop starts at login and the container should restart automatically.

### macOS

1. Open **Docker Desktop**
2. Go to **Settings**
3. Enable **Start Docker Desktop when you log in**
4. Start the container once:

```bash
docker compose up -d
```

After that, the container should restart when Docker Desktop launches.

### Linux

Make sure Docker starts on boot:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

Then start the container once:

```bash
docker compose up -d
```

Because the service uses `restart: unless-stopped`, it should come back after reboots as long as Docker starts normally.

---

## 7. Home Assistant setup

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

## 8. VS Code setup

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

## 9. Open WebUI and phone app setup

You can connect this Ollama server to browser-based and mobile-friendly apps too.

### Option A: Open WebUI

Open WebUI is a simple chat interface that works well on desktops, tablets, and phones.

#### Start Open WebUI in Docker

```bash
docker run -d \
  --name open-webui \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -v open-webui:/app/backend/data \
  --restart unless-stopped \
  ghcr.io/open-webui/open-webui:main
```

### If `host.docker.internal` does not work on Linux

Use the host machine's LAN IP instead:

```bash
docker run -d \
  --name open-webui \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://YOUR-COMPUTER-IP:11434 \
  -v open-webui:/app/backend/data \
  --restart unless-stopped \
  ghcr.io/open-webui/open-webui:main
```

#### Open it in a browser or on your phone

On the same network, open:

```text
http://YOUR-COMPUTER-IP:3000
```

Then choose one of these models:

- `qwen2.5:7b-instruct-q4_K_M` for general chat
- `deepseek-coder:16b-v2-lite-instruct-q4_K_M` for coding help

#### Check that Open WebUI is working

```bash
docker logs open-webui
docker ps --filter name=open-webui
```

If it is healthy and reachable, you should be able to chat from any browser on your LAN, including a phone browser.

### Option B: Similar phone apps

Many mobile apps and chat frontends can connect in one of two ways:

- **Direct Ollama support**
- **OpenAI-compatible custom server support**

When adding your server, try:

```text
http://YOUR-COMPUTER-IP:11434
```

If the app asks for a model name, use one of:

```text
qwen2.5:7b-instruct-q4_K_M
deepseek-coder:16b-v2-lite-instruct-q4_K_M
```

### If a phone app asks for an OpenAI-style endpoint

Some apps do not talk to Ollama directly. In that case, Open WebUI is usually the easier option because it provides a user-friendly interface in the browser without needing each phone app to support Ollama natively.

### Phone app checklist

Before trying to connect from a phone, confirm:

- the phone is on the same Wi-Fi/LAN
- the Ollama container is running and `healthy`
- the computer firewall allows the needed port
- you are using the correct IP address
- you are **not** using `localhost` on the phone

Use:

```text
http://YOUR-COMPUTER-IP:11434
http://YOUR-COMPUTER-IP:3000
```

Not:

```text
http://localhost:11434
http://localhost:3000
```

---

## 10. Common commands

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

### Check if the container is healthy

```bash
docker ps --filter name=homelab-llm
```

### Check Ollama directly inside the container

```bash
docker compose exec homelab-llm ollama ps
docker compose exec homelab-llm ollama list
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

## 11. Changing the default models

You can override either default model at startup:

```bash
GENERAL_MODEL=your-model CODING_MODEL=your-coding-model docker compose up -d --build
```

Example:

```bash
GENERAL_MODEL=qwen2.5:14b CODING_MODEL=deepseek-coder:33b docker compose up -d --build
```

---

## 12. Troubleshooting

### The first start takes a long time

That is normal. The models are several gigabytes each.

### Docker says it cannot connect to the daemon

Docker is probably not running yet.

- **Windows/macOS:** open Docker Desktop and wait until it says it is running
- **Linux:** run:

```bash
sudo systemctl start docker
```

Then try again:

```bash
docker compose up -d --build
```

### Port 11434 is already in use

Another app or container is already using the Ollama port.

Find the conflict:

```bash
docker ps
```

If needed, change the port mapping in `docker-compose.yml`, for example:

```yaml
ports:
  - "11435:11434"
```

Then connect clients to:

```text
http://YOUR-COMPUTER-IP:11435
```

### The container starts but becomes unhealthy

Check:

```bash
docker logs homelab-llm
docker inspect --format='{{json .State.Health}}' homelab-llm
```

Common causes:

- the host is out of RAM
- the disk is full
- Ollama is still busy downloading large models

If this happens during first startup, wait a bit longer and check logs again.

### The model download seems stuck

Check logs:

```bash
docker compose logs -f
```

Possible causes:

- slow internet
- temporary Ollama registry issue
- not enough disk space

You can restart the container:

```bash
docker compose restart
```

### The host is running out of disk space

Check Docker disk usage:

```bash
docker system df
```

This setup needs enough room for:

- Ollama image
- downloaded models
- future models you may add

### Another device cannot connect

Check:

- the server computer is powered on
- Docker container is running
- the container is `healthy`
- port `11434` is open in the firewall
- you used the correct LAN IP address

Test from the server itself first:

```bash
curl http://localhost:11434/api/tags
```

Then test from another machine on the LAN:

```bash
curl http://YOUR-COMPUTER-IP:11434/api/tags
```

### Home Assistant cannot find Ollama

Check:

- you entered `http://YOUR-COMPUTER-IP:11434`
- Home Assistant and the Ollama machine are on the same network
- the container is running and healthy
- your firewall is not blocking the connection

### VS Code extension cannot connect

Check:

- the extension is using the correct base URL
- you used `http://YOUR-COMPUTER-IP:11434`
- the selected model name exactly matches the installed model

You can confirm the available models with:

```bash
docker compose exec homelab-llm ollama list
```

### Open WebUI cannot connect to Ollama

Check:

- Open WebUI is running:

```bash
docker ps --filter name=open-webui
```

- the `OLLAMA_BASE_URL` is correct
- the Ollama container is running and healthy
- you used `host.docker.internal` on Windows/macOS or your LAN IP on Linux if needed

If needed, recreate Open WebUI with the correct `OLLAMA_BASE_URL`.

### A phone app cannot connect

Check:

- the phone is on the same local network
- you used the computer's LAN IP, not `localhost`
- the correct port is open:
  - `11434` for Ollama
  - `3000` for Open WebUI
- your firewall is not blocking the connection

Test the server from the phone browser first:

```text
http://YOUR-COMPUTER-IP:3000
```

### GPU is not being used

Check:

1. NVIDIA drivers are installed
2. NVIDIA Container Toolkit is installed
3. You started with the GPU override file:

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d --build
```

Then verify:

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml exec homelab-llm ollama ps
```

### The coding model feels slow

That usually means:

- CPU-only mode is being used
- there is not enough GPU VRAM
- the host does not have enough RAM

### It does not start automatically after reboot

Check:

- Docker Desktop is set to launch at login on Windows/macOS
- Docker service is enabled on Linux:

```bash
sudo systemctl status docker
```

- the container still has the `unless-stopped` restart policy:

```bash
docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' homelab-llm
```

### I want to reset everything

```bash
docker compose down -v
```

Then start again:

```bash
docker compose up -d --build
```
