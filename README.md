# llm-p2200

Configuration for a llama.cpp inference endpoint serving MoE models (Qwen3.6-35B-A3B / gemma-4-26B-A4B)
on a machine with a Quadro P2200 (5GB, Pascal sm_61). Everything needed is in this directory
(docker compose, `endpoint.sh`, model presets).

## Requirements
- NVIDIA driver (tested with 580 series), docker, nvidia-container-toolkit
- About 30GB RAM (experts live in RAM; the container memory limit is 20g in `docker-compose.yml`)
- A `.env` file: `cp .env.example .env`, then set `LLAMA_CPP_API_KEY` and `LLAMA_PORT`

## Model files
Put these under `./models` (the model directory, e.g. a symlink to `~/models`):

| File | Source (Hugging Face) |
|---|---|
| `qwen3.6-35b/Qwen3.6-35B-A3B-UD-IQ4_XS.gguf` | [unsloth/Qwen3.6-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) |
| `gemma-4-26B-A4B/gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf` | [unsloth/gemma-4-26B-A4B-it-qat-GGUF](https://huggingface.co/unsloth/gemma-4-26B-A4B-it-qat-GGUF) |
| `gemma-4-26B-A4B/mmproj-F16.gguf` | same as above |

Download example (the `hf` CLI comes from `pip install -U huggingface_hub`):
```
hf download unsloth/Qwen3.6-35B-A3B-GGUF Qwen3.6-35B-A3B-UD-IQ4_XS.gguf --local-dir models/qwen3.6-35b
hf download unsloth/gemma-4-26B-A4B-it-qat-GGUF gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf mmproj-F16.gguf --local-dir models/gemma-4-26B-A4B
```

## Usage
```
./endpoint.sh build --pull   # first time: pull the latest llama.cpp image
./endpoint.sh start          # also: restart / stop / status. Use restart to apply ini changes
```
Set the preset name as `"model"` in a request to load it on demand (only one model is loaded at a time).

| Use | Preset | Context | Approx. generation speed |
|---|---|---|---|
| hermes | `qwen3.6-35b-64k` / `gemma-4-26B-A4B-64k` | 64k | ~17 / ~15-17 t/s |
| claude code | `qwen3.6-35b-200k` | 200k | ~14 t/s |
| claude code | `gemma-4-26B-A4B-200k` | 200k | ~9.5 t/s |

200k requires `ctv=q4_0` and leaves only 600MiB for the GPU cache. Qwen 200k uses 5.04/5.05GB of VRAM, so there is almost no headroom.
If startup fails for lack of VRAM (HTTP 500 / `cudaMalloc failed` in the log), lower `moe-cache-mib` in steps of 200.

Smoke test: `./bench.py <preset>` (measures short-prompt generation speed and a ~2.7k-token long prompt).

## Files
`models.ini` presets / `endpoint.sh` control script / `docker-compose.yml`, `Dockerfile`, `supervisor.sh`, `healthcheck-slots.sh` container definition / `bench.py` smoke test
