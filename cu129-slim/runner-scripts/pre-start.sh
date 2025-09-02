#!/usr/bin/env bash
set -euo pipefail

# --- Hugging Face ---
if ! command -v hf >/dev/null 2>&1; then
  echo "[setup] Installing Hugging Face CLI..."
  pip install --quiet "huggingface_hub[cli]"
fi

if [[ -n "${HUGGINGFACE_TOKEN:-}" ]]; then
  export HF_TOKEN="${HUGGINGFACE_TOKEN}"
  echo "[setup] Authenticating with Hugging Face..."
  hf auth login --token "${HUGGINGFACE_TOKEN}" --quiet || {
    echo "[setup] ⚠️ Hugging Face auth failed"; exit 1;
  }
fi

# --- CivitAI ---
if [[ -n "${CIVITAI_TOKEN:-}" ]]; then
  echo "[setup] Using CivitAI token (length: ${#CIVITAI_TOKEN})"
else
  echo "[setup] ⚠️ No CivitAI token found, public-only downloads may fail"
fi

echo "########################################"
echo "[INFO] Downloading ALWAYS models..."
echo "########################################"

# -------------------------------
# Hugging Face (requires HF_TOKEN)
# -------------------------------
# YOLOv11n face detector (rename)
hf download AdamCodd/YOLOv11n-face-detection model.pt \
  --local-dir /workspace/ComfyUI/models/ultralytics/bbox
mv -f /workspace/ComfyUI/models/ultralytics/bbox/model.pt \
      /workspace/ComfyUI/models/ultralytics/bbox/yolov11nface.pt
hf download GritTin/LoraStableDiffusion Eyeful_v2-Paired.pt --local-dir /workspace/ComfyUI/models/ultralytics/bbox
hf download RyanJames/yolo12l-person-seg yolo12l-person-seg-extended.pt --local-dir /workspace/ComfyUI/models/ultralytics/bbox

# SAM
hf download xingren23/comfyflow-models sams/sam_vit_h_4b8939.pth \
  --local-dir /workspace/ComfyUI/models/sams

# Text encoder
hf download zer0int/CLIP-GmP-ViT-L-14 ViT-L-14-TEXT-detail-improved-hiT-GmP-TE-only-HF.safetensors \
  --local-dir /workspace/ComfyUI/models/text_encoders

# CLIP Vision
hf download funnewsr/sigclip_vision_patch14_384 sigclip_vision_patch14_384.safetensors \
  --local-dir /workspace/ComfyUI/models/clip_vision

# PuLID
hf download guozinan/PuLID pulid_flux_v0.9.1.safetensors \
  --local-dir /workspace/ComfyUI/models/pulid
hf download guozinan/PuLID pulid_v1.1.safetensors \
  --local-dir /workspace/ComfyUI/models/pulid

# -------------------------------
# Upscalers (direct URLs)
# -------------------------------
mkdir -p /workspace/ComfyUI/models/upscale_models
cd /workspace/ComfyUI/models/upscale_models

# LiveActionV1 SPAN
aria2c -x16 -s16 --continue=true --always-resume=true \
  --check-integrity=true --content-disposition=true \
  --auto-file-renaming=false --allow-overwrite=true \
  --file-allocation=none --http-accept-gzip=false \
  -d /workspace/ComfyUI/models/upscale_models \
  "https://raw.githubusercontent.com/jcj83429/upscaling/f73a3a02874360ec6ced18f8bdd8e43b5d7bba57/2xLiveActionV1_SPAN/2xLiveActionV1_SPAN_490000.pth"

# Lexica SwinIR
aria2c -x16 -s16 --continue=true --always-resume=true \
  --check-integrity=true --content-disposition=true \
  --auto-file-renaming=false --allow-overwrite=true \
  --file-allocation=none --http-accept-gzip=false \
  -d /workspace/ComfyUI/models/upscale_models \
  "https://github.com/Phhofm/models/raw/main/2xLexicaSwinIR/2xLexicaSwinIR.pth"


echo "[INFO] Continue without pre-start script."
