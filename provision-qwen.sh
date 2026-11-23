#!/bin/bash
set -Eeuo pipefail

trap 'echo "[ERROR] Ошибка в строке $LINENO" >&2' ERR

echo "=== Установка моделей Qwen-Image-Edit-2511 ==="

# Можно явно задать через переменную окружения:
# COMFYUI_DIR=/workspace/ComfyUI

if [[ -n "${COMFYUI_DIR:-}" ]]; then
    if [[ ! -f "$COMFYUI_DIR/main.py" ]]; then
        echo "[ERROR] В COMFYUI_DIR не найден main.py: $COMFYUI_DIR" >&2
        exit 1
    fi
else
    candidates=(
        "${WORKSPACE:-/workspace}/ComfyUI"
        "/workspace/ComfyUI"
        "/workspace/comfyui"
        "/opt/ComfyUI"
        "/opt/comfyui"
        "/root/ComfyUI"
    )

    COMFYUI_DIR=""

    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate/main.py" ]]; then
            COMFYUI_DIR="$candidate"
            break
        fi
    done

    if [[ -z "$COMFYUI_DIR" ]]; then
        echo "[ERROR] Не удалось найти установленный ComfyUI." >&2
        echo "Укажите путь в переменной COMFYUI_DIR." >&2
        exit 1
    fi
fi

command -v wget >/dev/null 2>&1 || {
    echo "[ERROR] Не установлен wget." >&2
    exit 1
}

MODELS_DIR="$COMFYUI_DIR/models"

mkdir -p \
    "$MODELS_DIR/diffusion_models" \
    "$MODELS_DIR/text_encoders" \
    "$MODELS_DIR/vae" \
    "$MODELS_DIR/loras"

echo "[INFO] ComfyUI: $COMFYUI_DIR"
echo "[INFO] Папка моделей: $MODELS_DIR"
echo "[INFO] Свободное место:"
df -h "$MODELS_DIR"

download_model() {
    local subdir="$1"
    local filename="$2"
    local url="$3"

    local target="$MODELS_DIR/$subdir/$filename"
    local partial="${target}.part"

    if [[ -s "$target" ]]; then
        echo "[SKIP] Уже существует: $target"
        return 0
    fi

    echo
    echo "[DOWNLOAD] $filename"

    if ! wget \
        --continue \
        --tries=10 \
        --waitretry=5 \
        --timeout=60 \
        --progress=bar:force \
        --output-document="$partial" \
        "$url"; then
        echo "[ERROR] Не удалось скачать: $filename" >&2
        echo "[INFO] Частичный файл сохранён: $partial" >&2
        return 1
    fi

    if [[ ! -s "$partial" ]]; then
        echo "[ERROR] Получен пустой файл: $filename" >&2
        return 1
    fi

    mv -f "$partial" "$target"
    echo "[OK] $target"
}

download_model \
    "diffusion_models" \
    "qwen_image_edit_2511_fp8mixed.safetensors" \
    "https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors"

download_model \
    "text_encoders" \
    "qwen_2.5_vl_7b_fp8_scaled.safetensors" \
    "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"

download_model \
    "vae" \
    "qwen_image_vae.safetensors" \
    "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors"

download_model \
    "loras" \
    "Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors" \
    "https://huggingface.co/lightx2v/Qwen-Image-Edit-2511-Lightning/resolve/main/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"

echo
echo "=== Загрузка завершена ==="

ls -lh \
    "$MODELS_DIR/diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors" \
    "$MODELS_DIR/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" \
    "$MODELS_DIR/vae/qwen_image_vae.safetensors" \
    "$MODELS_DIR/loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"

echo
echo "Обновите список моделей в ComfyUI."
echo "Если модели не появились — перезапустите ComfyUI."