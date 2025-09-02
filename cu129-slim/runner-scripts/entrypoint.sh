#!/bin/bash

set -e

echo "########################################"

# Read tokens from files if they exist
if [ -n "${HUGGINGFACE_TOKEN_FILE:-}" ] && [ -f "${HUGGINGFACE_TOKEN_FILE}" ]; then
  HUGGINGFACE_TOKEN=$(cat "${HUGGINGFACE_TOKEN_FILE}")
  export HUGGINGFACE_TOKEN
  log "Loaded Hugging Face token from file"
fi

if [ -n "${CIVITAI_TOKEN_FILE:-}" ] && [ -f "${CIVITAI_TOKEN_FILE}" ]; then
  CIVITAI_TOKEN=$(cat "${CIVITAI_TOKEN_FILE}")
  export CIVITAI_TOKEN
  log "Loaded CivitAI token from file"
fi

# Hugging Face login
if [[ -n "${HUGGINGFACE_TOKEN:-}" ]]; then
  try hf auth login --token "${HUGGINGFACE_TOKEN}"
fi

# Run user's set-proxy script
cd /root
if [ ! -f "/root/user-scripts/set-proxy.sh" ] ; then
    mkdir -p /root/user-scripts
    cp /runner-scripts/set-proxy.sh.example /root/user-scripts/set-proxy.sh
else
    echo "[INFO] Running set-proxy script..."

    chmod +x /root/user-scripts/set-proxy.sh
    source /root/user-scripts/set-proxy.sh
fi ;

# Copy ComfyUI from cache to workdir if it doesn't exist
cd /root
if [ ! -f "/root/ComfyUI/main.py" ] ; then
    mkdir -p /root/ComfyUI
    # 'cp --archive': all file timestamps and permissions will be preserved
    # 'cp --update=none': do not overwrite
    if cp --archive --update=none "/default-comfyui-bundle/ComfyUI/." "/root/ComfyUI/" ; then
        echo "[INFO] Setting up ComfyUI..."
    else
        echo "[ERROR] Failed to copy ComfyUI bundle to '/root/ComfyUI'" >&2
        exit 1
    fi
else
    echo "[INFO] Using existing ComfyUI in user storage..."
fi

# Syncthing
if [[ "${START_SYNCTHING:-1}" != "0" ]]; then
  if command -v syncthing >/dev/null 2>&1; then
    log "Initializing Syncthing..."
    
    # Set environment variables for Syncthing
    export ST_CONFIG="${ST_CONFIG:-/root/.config/syncthing}"
    export SYNC_FOLDER="${SYNC_FOLDER:-/workspace/ComfyUI/output}"
    
    # Ensure the sync folder exists
    mkdir -p "$SYNC_FOLDER"
    chmod 777 "$SYNC_FOLDER"
    
    # Initialize Syncthing configuration
    if [ -f "${WORKSPACE}/scripts/syncthing-init.sh" ]; then
      log "Running Syncthing initialization script..."
      bash "${WORKSPACE}/scripts/syncthing-init.sh"
    else
      log "Warning: Syncthing initialization script not found at ${WORKSPACE}/scripts/syncthing-init.sh"
    fi
    
    # Start Syncthing in the background
    log "Starting Syncthing..."
    nohup syncthing -no-browser \
      -gui-address=0.0.0.0:8384 \
      -home "$ST_CONFIG" \
      -logfile=/dev/stdout \
      -log-max-old-files=3 \
      -log-max-size=1 \
      -verbose \
      > "${WORKSPACE}/syncthing.log" 2>
      
# Run user's pre-start script
cd /root
if [ ! -f "/root/user-scripts/pre-start.sh" ] ; then
    mkdir -p /root/user-scripts
    cp /runner-scripts/pre-start.sh.example /root/user-scripts/pre-start.sh
else
    echo "[INFO] Running pre-start script..."

    chmod +x /root/user-scripts/pre-start.sh
    source /root/user-scripts/pre-start.sh
fi ;

echo "[INFO] Starting ComfyUI..."
echo "########################################"

# Let .pyc files be stored in one place
export PYTHONPYCACHEPREFIX="/root/.cache/pycache"
# Let PIP install packages to /root/.local
export PIP_USER=true
# Add above to PATH
export PATH="${PATH}:/root/.local/bin"
# Suppress [WARNING: Running pip as the 'root' user]
export PIP_ROOT_USER_ACTION=ignore

cd /root

python3 ./ComfyUI/main.py --listen --port 8188 ${CLI_ARGS}
