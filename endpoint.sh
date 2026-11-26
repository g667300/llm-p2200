#!/bin/bash
# Control the llama.cpp endpoint for the P2200. Model presets are in models.ini.
#   ./endpoint.sh build [--pull] | start [--no-api-key] | restart [--no-api-key] | stop | status
# restart recreates the container (to apply ini changes).
# --no-api-key starts without --api-key even if LLAMA_CPP_API_KEY is unset.
set -euo pipefail
cd "$(dirname "$0")"

env_file=.env
if [ ! -f "$env_file" ]; then
    echo "missing $env_file: cp .env.example .env" >&2
    exit 2
fi
compose=(docker compose --env-file "$env_file" -f docker-compose.yml)

# compose expands the whole file regardless of subcommand, so pass an empty dummy for non-start commands.
export LLAMA_API_KEY_ARGS=""

case "${1:-status}" in
    build)
        build_args=()
        if [ $# -gt 1 ]; then
            [ "$2" = --pull ] && [ $# -eq 2 ] || { echo "usage: $0 build [--pull]" >&2; exit 2; }
            build_args=(--pull)
        fi
        "${compose[@]}" build "${build_args[@]}" llama-server
        ;;
    start|restart)
        cmd=$1
        no_api_key=false
        for arg in "${@:2}"; do
            [ "$arg" = --no-api-key ] || { echo "usage: $0 $cmd [--no-api-key]" >&2; exit 2; }
            no_api_key=true
        done
        api_key=$(sed -n 's/^LLAMA_CPP_API_KEY=//p' "$env_file")
        if [ -n "$api_key" ]; then
            export LLAMA_API_KEY_ARGS="--api-key $api_key"
        elif [ "$no_api_key" = true ]; then
            echo "warning: starting WITHOUT --api-key" >&2
        else
            echo "error: LLAMA_CPP_API_KEY is empty in $env_file (or pass --no-api-key)" >&2
            exit 2
        fi
        up_args=(-d --wait --wait-timeout 300)
        [ "$cmd" = restart ] && up_args+=(--force-recreate)
        "${compose[@]}" up "${up_args[@]}"
        ;;
    stop) "${compose[@]}" stop ;;
    status) "${compose[@]}" ps ;;
    *)
        echo "usage: $0 {build [--pull]|start [--no-api-key]|restart [--no-api-key]|stop|status}" >&2
        exit 2
        ;;
esac
