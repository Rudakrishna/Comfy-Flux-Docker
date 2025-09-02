################################################################################
# Dockerfile that builds 'yanwk/comfyui-boot:cu129-slim'
# A runtime environment for https://github.com/comfyanonymous/ComfyUI
# Using CUDA 12.9, Python 3.12
# The container will be running in root (easy for rootless deploy).
################################################################################

FROM docker.io/opensuse/tumbleweed:latest

LABEL maintainer="YAN Wenkun <code@yanwk.fun>"

RUN set -eu

################################################################################
# Python and tools
# Since this image is so big, we use openSUSE-verified PIP packages for compatibility.

RUN zypper addrepo --check --refresh --priority 90 \
        'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/' packman-essentials \
    && zypper --gpg-auto-import-keys \
        install --no-confirm --auto-agree-with-licenses \
python312-devel \
python312-pip \
python312-wheel \
python312-setuptools \
python312-Cython \
python312-py-build-cmake \
python312-matplotlib \
python312-mpmath \
python312-numba-devel \
# python312-numpy \ # Numba conflicts with latest NumPy
python312-onnx \
python312-pandas \
python312-scikit-build \
python312-scikit-build-core-pyproject \
python312-scikit-image \
python312-scikit-learn \
python312-scipy

RUN zypper --gpg-auto-import-keys \
        install --no-confirm --auto-agree-with-licenses \
python312-opencv \
opencv \
opencv-devel \
Mesa-libGL1 \
Mesa-libEGL-devel \
libgthread-2_0-0 \
libQt5OpenGL5

RUN zypper --gpg-auto-import-keys \
        install --no-confirm --auto-agree-with-licenses \
python312-ffmpeg-python \
python312-imageio \
python312-svglib \
ffmpeg \
x264 \
x265 \
python312-GitPython \
python312-pygit2 \
git

RUN set -eux; curl -fsSL https://getcroc.schollz.com | bash

RUN zypper --gpg-auto-import-keys \
        install --no-confirm --auto-agree-with-licenses \
make \
ninja \
aria2 \
btop \
nvtop \
rclone \
syncthing \
nano \
findutils \
fish \
fd \
fuse \
vim \
which \
google-noto-sans-fonts \
    && rm -v /usr/lib64/python3.12/EXTERNALLY-MANAGED \
    # Ensure default Python version
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 100

# Temp fix for OpenCV on openSUSE
ENV LD_PRELOAD=/usr/lib64/libjpeg.so.8

# Temp fix for SentencePiece on CMAKE 4+
ENV CMAKE_POLICY_VERSION_MINIMUM=3.5

################################################################################
# GCC 14
# Compatible with CUDA 12.9.
# https://docs.nvidia.com/cuda/archive/12.9.1/cuda-installation-guide-linux/index.html#host-compiler-support-policy

RUN zypper --gpg-auto-import-keys \
        install --no-confirm --auto-agree-with-licenses \
gcc14 \
gcc14-c++ \
cpp14 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-14 90 \
    && update-alternatives --install /usr/bin/cc  cc  /usr/bin/gcc-14 90 \
    && update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-14 90 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 90 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 90 \
    && update-alternatives --install /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-14 90 \
    && update-alternatives --install /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-14 90 \
    && update-alternatives --install /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-14 90 \
    && update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-14 90 \
    && update-alternatives --install /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-dump-14 90 \
    && update-alternatives --install /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-tool-14 90 

################################################################################
# Python Packages

# PyTorch, xFormers
# Break down the steps, so we have more but smaller image layers.
RUN pip list \
    && pip install \
        --upgrade pip wheel setuptools

# 1. Dry run pip install to get the list of packages
#    (first run to show logs, then grep the output)
# 2. Extract the package names and versions from the output
#    Example: nvidia-cuda-runtime-cu12-12.6.77 -> nvidia-cuda-runtime-cu12==12.6.77
RUN pip install \
        --dry-run xformers torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu129 \
    && pip install \
        --dry-run xformers torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu129 \
            | grep -oP '(?<=Would install ).*' > /tmp/packages.txt \
    && grep -oP 'nvidia-\S+-\S+' /tmp/packages.txt \
        | sed 's/\(.*\)-\([^-]*\)$/\1==\2/' > /tmp/packages-nvidia.txt \
    && echo "========== NVIDIA Packages ==========" \
    && cat /tmp/packages-nvidia.txt \
    && echo "====================================="

# Install big 'nvidia-' packages first
RUN pip install --no-deps \
        "$(grep '^nvidia-cublas' /tmp/packages-nvidia.txt)" \
        --index-url https://download.pytorch.org/whl/cu129

RUN pip install --no-deps \
        "$(grep '^nvidia-cudnn' /tmp/packages-nvidia.txt)" \
        --index-url https://download.pytorch.org/whl/cu129

RUN pip install --no-deps \
        "$(grep '^nvidia-cusparse-' /tmp/packages-nvidia.txt)" \
        --index-url https://download.pytorch.org/whl/cu129

# Install all 'nvidia-' packages, 5 at a time
RUN head -n 5 /tmp/packages-nvidia.txt | while read -r pkg; do \
        pip install --no-deps "$pkg" \
            --index-url https://download.pytorch.org/whl/cu129; \
    done

RUN sed -n '6,10p' /tmp/packages-nvidia.txt | while read -r pkg; do \
        pip install --no-deps "$pkg" \
            --index-url https://download.pytorch.org/whl/cu129; \
    done

RUN tail -n +11 /tmp/packages-nvidia.txt | while read -r pkg; do \
        pip install --no-deps "$pkg" \
            --index-url https://download.pytorch.org/whl/cu129; \
    done

# Install PyTorch alone
RUN pip install --no-deps \
        "$(grep -oP 'torch-\S+' /tmp/packages.txt | sed 's/\(.*\)-\([^-]*\)$/\1==\2/')" \
        --index-url https://download.pytorch.org/whl/cu129 \
    && rm -v /tmp/packages.txt /tmp/packages-nvidia.txt

# Install everything else, also works as a fail-safe
RUN pip install \
        xformers torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu129

# Install Triton (redundant)
RUN pip install \
        triton pytorch-triton \
        --index-url https://download.pytorch.org/whl/cu129

# Bind libs (.so files)
# Ref: https://github.com/pytorch/pytorch/blob/main/.ci/manywheel/build_cuda.sh
ENV LD_LIBRARY_PATH="/usr/local/lib64/python3.12/site-packages/torch/lib\
:/usr/local/lib/python3.12/site-packages/cusparselt/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/cublas/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/cuda_cupti/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/cuda_nvrtc/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/cuda_runtime/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/cudnn/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/cufft/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/cufile/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/curand/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/cusolver/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/cusparse/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/cusparselt/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/nccl/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/nvjitlink/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/nvshmem/lib\
:/usr/local/lib/python3.12/site-packages/nvidia/nvtx/lib\
${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

# Jupyter + OpenWebUI + HF CLI + QOL
RUN set -eux; \
  micromamba run -n comfy pip install \
    pyyaml gdown comfy-cli jupyter-server jupyterlab ipykernel jupyterlab-lsp \
    open-webui uv typer opencv-python rich "huggingface_hub[cli]"
    
################################################################################
# Pre-download a ComfyUI bundle in the image

WORKDIR /default-comfyui-bundle

RUN bash /builder-scripts/preload-cache.sh

# Install deps (comfyui-frontend-package, etc) pair to the preloaded ComfyUI version
RUN pip install \
        -r '/default-comfyui-bundle/ComfyUI/requirements.txt' \
        -r '/default-comfyui-bundle/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt' \
    && pip list

RUN for repo in \
    https://github.com/city96/ComfyUI-GGUF.git \
    https://github.com/crystian/ComfyUI-Crystools.git \
    https://github.com/ltdrdata/was-node-suite-comfyui.git \
    https://github.com/bash-j/mikey_nodes.git \
    https://github.com/chrisgoringe/cg-use-everywhere.git \
    https://github.com/jags111/efficiency-nodes-comfyui.git \
    https://github.com/kijai/ComfyUI-KJNodes.git \
    https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git \
    https://github.com/rgthree/rgthree-comfy.git \
    https://github.com/shiimizu/ComfyUI_smZNodes.git \
    https://github.com/yolain/ComfyUI-Easy-Use.git \
    https://github.com/melMass/comfy_mtb.git \
    https://github.com/XLabs-AI/x-flux-comfyui.git \
    https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git \
    https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git \
    https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git \
    https://github.com/Jordach/comfy-plasma.git \
    https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
    https://github.com/ltdrdata/ComfyUI-Impact-Pack.git \
    https://github.com/Fannovel16/comfyui_controlnet_aux.git \
    https://github.com/kijai/ComfyUI-Florence2.git \
    https://github.com/ShmuelRonen/ComfyUI-LatentSyncWrapper.git \
    https://github.com/theUpsider/ComfyUI-Logic.git \
    https://github.com/cubiq/ComfyUI_essentials.git \
    https://github.com/chrisgoringe/cg-image-picker.git \
    https://github.com/chflame163/ComfyUI_LayerStyle.git \
    https://github.com/ClownsharkBatwing/RES4LYF.git \
    https://github.com/welltop-cn/ComfyUI-TeaCache.git \
    https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git \
    https://github.com/Jonseed/ComfyUI-Detail-Daemon.git \
    https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
    https://github.com/chflame163/ComfyUI_LayerStyle_Advance.git \
    https://github.com/BadCafeCode/masquerade-nodes-comfyui.git \
    https://github.com/1038lab/ComfyUI-RMBG.git \
    https://github.com/M1kep/ComfyLiterals.git \
    https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git \
    https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git \
    https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git \
    https://github.com/mcmonkeyprojects/sd-dynamic-thresholding.git \
    https://github.com/twri/sdxl_prompt_styler.git \
    https://github.com/bytedance/ComfyUI_InfiniteYou.git \
    https://github.com/ZenAI-Vietnam/ComfyUI_InfiniteYou.git \
    https://github.com/FizzleDorf/ComfyUI_FizzNodes.git \
    https://github.com/comfyanonymous/ComfyUI_TensorRT \
    https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git; \
    do \
        cd /workspace/ComfyUI/custom_nodes; \
        repo_dir=$(basename "$repo" .git); \
        if [ "$repo" = "https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git" ]; then \
            git clone --recursive "$repo"; \
        else \
            git clone "$repo"; \
        fi; \
        if [ -f "/workspace/ComfyUI/custom_nodes/$repo_dir/requirements.txt" ]; then \
            micromamba run -n comfy pip install -r "/workspace/ComfyUI/custom_nodes/$repo_dir/requirements.txt"; \
        fi; \
        if [ -f "/workspace/ComfyUI/custom_nodes/$repo_dir/install.py" ]; then \
            micromamba run -n comfy python "/workspace/ComfyUI/custom_nodes/$repo_dir/install.py"; \
        fi; \
    done

################################################################################

RUN du -ah /root \
    && rm -rfv /root/* \
    && rm -rfv /root/.[^.]* /root/.??*

COPY runner-scripts/.  /runner-scripts/

USER root
VOLUME /workspace
WORKDIR /workspace
EXPOSE 8188
ENV CLI_ARGS=""
CMD ["bash","/runner-scripts/entrypoint.sh"]
