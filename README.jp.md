# llm-p2200

[English](README.md) | 日本語

Quadro P2200 (5GB, Pascal sm_61) を積んだマシンで、MoEモデル(Qwen3.6-35B-A3B / gemma-4-26B-A4B)の
llama.cpp 推論エンドポイントを動かすための設定一式。必要なもの(docker compose, `endpoint.sh`, モデルプリセット)は
すべてこのディレクトリにある。

## 前提
- NVIDIAドライバ(580系で確認)、docker、nvidia-container-toolkit
- RAM 約30GB(expertをRAMに置く。コンテナのメモリ上限は `docker-compose.yml` の 20g)
- `.env` を用意する(`cp .env.example .env` し、`LLAMA_CPP_API_KEY` と `LLAMA_PORT` を設定)

## モデルの配置
`./models`(モデル置き場、例 `~/models` へのリンク)に次を置く:

| ファイル | 取得元(Hugging Face) |
|---|---|
| `qwen3.6-35b/Qwen3.6-35B-A3B-UD-IQ4_XS.gguf` | [unsloth/Qwen3.6-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) |
| `qwen3.6-35b/mmproj-F16.gguf` | 同上 |
| `gemma-4-26B-A4B/gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf` | [unsloth/gemma-4-26B-A4B-it-qat-GGUF](https://huggingface.co/unsloth/gemma-4-26B-A4B-it-qat-GGUF) |
| `gemma-4-26B-A4B/mmproj-F16.gguf` | 同上 |

ダウンロード例(`hf` CLI は `pip install -U huggingface_hub` で入る):
```
hf download unsloth/Qwen3.6-35B-A3B-GGUF Qwen3.6-35B-A3B-UD-IQ4_XS.gguf mmproj-F16.gguf --local-dir models/qwen3.6-35b
hf download unsloth/gemma-4-26B-A4B-it-qat-GGUF gemma-4-26B-A4B-it-qat-UD-Q4_K_XL.gguf mmproj-F16.gguf --local-dir models/gemma-4-26B-A4B
```

## 起動
```
./endpoint.sh build --pull   # 初回: 最新の llama.cpp イメージを取得
./endpoint.sh start          # restart / stop / status も同じ。ini変更の反映は restart
```
リクエストの `"model"` にプリセット名を指定するとオンデマンドでロードされる(同時に載るのは1モデル)。

| 用途 | プリセット名 | コンテキスト | 生成速度の目安 |
|---|---|---|---|
| hermes | `qwen3.6-35b-64k` / `gemma-4-26B-A4B-64k` | 64k | 約17 / 約15〜17 t/s |
| claude code | `qwen3.6-35b-200k` | 200k | 約14 t/s |
| claude code | `gemma-4-26B-A4B-200k` | 200k | 約9.5 t/s |

200kは `ctv=q4_0` が必須で、GPUキャッシュが600MiBしか取れない。Qwen 200kはVRAM 5.04/5.05GBで余裕がない。
VRAMが足りず起動に失敗する(HTTP 500 / ログに `cudaMalloc failed`)場合は `moe-cache-mib` を200ずつ下げる。

動作確認: `./bench.py <プリセット名>`(短文の生成速度と約2.7k tokの長文を測る)。

## ファイル
`models.ini` プリセット / `endpoint.sh` 操作スクリプト / `docker-compose.yml`, `Dockerfile`, `supervisor.sh`, `healthcheck-slots.sh` コンテナ定義 / `bench.py` 動作確認
