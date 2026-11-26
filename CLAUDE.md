# llm-p2200

llama.cpp endpoint configuration for a machine with a Quadro P2200 (5GB, Pascal sm_61). See `README.md` for usage.
Self-contained in this directory (docker compose, `endpoint.sh`, API key in `.env`).

- `models.ini`: llama-server router-mode presets. Section names are the API `model` names. Apply changes with `./endpoint.sh restart`.
- `endpoint.sh`: build/start/restart/stop/status. `docker-compose.yml`, `Dockerfile`, `supervisor.sh`, `healthcheck-slots.sh` define the container.
- `bench.py`: `[PORT=8081] ./bench.py <model>`.
- The API key lives in `.env` (gitignored); never write it into the repository.
- `moe-cache-mib` is the largest value that fits in VRAM. On OOM (HTTP 500 / `cudaMalloc failed`), lower it in steps of 200. 200k requires `ctv=q4_0`.
- When writing scripts that edit the ini, do not break existing sections. Commit only when asked.
