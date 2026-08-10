# NVIDIA AI Enterprise / GPU Computing Cheat Sheet

## Installation & Setup

```bash
# Check NVIDIA driver and GPU status
nvidia-smi

# Check driver version only
nvidia-smi --query-gpu=driver_version --format=csv,noheader

# Check CUDA runtime version
nvcc --version

# --- NVIDIA Container Toolkit (Ubuntu/Debian) ---
# Add NVIDIA package repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# --- NVIDIA Container Toolkit (RHEL/CentOS/Rocky) ---
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

sudo yum install -y nvidia-container-toolkit

# Configure container runtimes
nvidia-ctk runtime configure --runtime=docker
nvidia-ctk runtime configure --runtime=containerd
nvidia-ctk runtime configure --runtime=crio

# Restart Docker after configuring
sudo systemctl restart docker

# Check nvidia-ctk version
nvidia-ctk --version

# --- NGC CLI install ---
# Download NGC CLI (Linux x86_64)
wget -O ngccli_linux.zip \
  https://api.ngc.nvidia.com/v2/resources/nvidia/ngc-apps/ngc_cli/versions/3.41.4/files/ngccli_linux.zip
unzip ngccli_linux.zip
chmod +x ngc-cli/ngc
sudo mv ngc-cli/ngc /usr/local/bin/ngc

# Authenticate NGC CLI (API key from https://ngc.nvidia.com)
ngc config set
# Interactive: enter API key, org, team, ace when prompted

# Verify NGC CLI login
ngc config current
```

---

## nvidia-smi – GPU Management

```bash
# Quick overview of all GPUs
nvidia-smi

# Full query (all GPU attributes)
nvidia-smi -q

# Full query for a specific GPU
nvidia-smi -q -i 0

# List all GPUs with their UUIDs
nvidia-smi -L

# Watch GPU utilization every 1 second
nvidia-smi dmon -s u -d 1

# Watch multiple stats: utilization, memory, power, clock
nvidia-smi dmon -s umc -d 2

# Process-level GPU monitoring
nvidia-smi pmon -s um -d 1

# List running compute processes
nvidia-smi --query-compute-apps=pid,process_name,used_memory \
  --format=csv,noheader

# Memory info per GPU
nvidia-smi --query-gpu=index,name,memory.total,memory.used,memory.free \
  --format=csv,noheader

# Set persistence mode (faster subsequent GPU initialization)
sudo nvidia-smi -pm 1           # enable
sudo nvidia-smi -pm 0           # disable

# Set power limit (watts) for GPU 0
sudo nvidia-smi -pl 250 -i 0

# Set compute mode (0=Default, 1=Exclusive Process, 2=Prohibited)
sudo nvidia-smi -c 0 -i 0      # Default – multiple processes allowed
sudo nvidia-smi -c 1 -i 0      # Exclusive Process – one process at a time

# GPU topology / NVLink interconnect map
nvidia-smi topo -m

# Enable MIG mode on GPU 0 (requires reboot or driver reload)
sudo nvidia-smi -i 0 -mig 1

# Disable MIG mode on GPU 0
sudo nvidia-smi -i 0 -mig 0

# Set fan speed (requires supported GPU, speed in %)
sudo nvidia-smi --auto-boost-default=0 -i 0
nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=80"

# Reset GPU 0 (clear error state)
sudo nvidia-smi --gpu-reset -i 0
```

---

## NGC CLI – Catalog & Registry

```bash
# Show current NGC configuration
ngc config current

# Reconfigure NGC (API key / org / team)
ngc config set

# --- Browse the NGC Catalog ---
# List available container images
ngc catalog list containers

# List available models
ngc catalog list models

# List available datasets
ngc catalog list datasets

# List available Helm charts
ngc catalog list helm-charts

# Search catalog by keyword
ngc catalog search --query "llama"

# --- Registry (private org registry) ---
# List images in org registry
ngc registry image list

# Pull a container image from NGC
ngc registry image pull nvcr.io/nvidia/pytorch:24.05-py3

# List models in org registry
ngc registry model list

# Download a model
ngc registry model download-version \
  nvidia/nemo/megatron-gpt-345m:1.0

# List datasets
ngc registry resource list

# Download a dataset
ngc registry resource download-version \
  nvidia/default/pilotnet-data:1

# --- Org & Team context ---
# Show current org
ngc config current | grep org

# Switch org context
ngc config set --org my-org

# Switch team context
ngc config set --team my-team

# List orgs available to your API key
ngc org list
```

---

## NVIDIA Container Runtime

```bash
# Run container with ALL GPUs
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi

# Run container with specific GPUs (by index)
docker run --rm --gpus '"device=0,1"' \
  nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi

# Run container with specific GPU UUID
docker run --rm --gpus '"device=GPU-abc12345-1234-1234-1234-abc123456789"' \
  nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi

# Limit capabilities to compute and utility
docker run --rm \
  --gpus '"capabilities=compute,utility"' \
  nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi

# All capabilities (compute, utility, graphics, video, display)
docker run --rm \
  --gpus '"capabilities=all"' \
  nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi

# GPU environment variables (set in Dockerfile or -e flag)
# Make all GPUs visible (default when --gpus all is used)
docker run --rm \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  nvcr.io/nvidia/pytorch:24.05-py3 python -c "import torch; print(torch.cuda.device_count())"

# Expose only GPU 0 via env var
docker run --rm \
  -e NVIDIA_VISIBLE_DEVICES=0 \
  nvcr.io/nvidia/pytorch:24.05-py3 nvidia-smi

# Disable GPU access entirely
docker run --rm \
  -e NVIDIA_VISIBLE_DEVICES=none \
  nvcr.io/nvidia/pytorch:24.05-py3 python -c "import torch; print(torch.cuda.is_available())"

# --- CDI (Container Device Interface) ---
# Generate CDI device specification (for containerd/CRI-O)
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

# List CDI devices
nvidia-ctk cdi list

# Validate CDI spec
nvidia-ctk cdi validate --input=/etc/cdi/nvidia.yaml

# Use CDI device in Docker (requires Docker 25+)
docker run --rm \
  --device nvidia.com/gpu=all \
  nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

---

## GPU Operator (Kubernetes)

```bash
# Add NVIDIA Helm repo
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

# Install GPU Operator (latest)
helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace

# Install with specific CUDA driver version
helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace \
  --set driver.version="550.54.14"

# Install with MIG strategy (single or mixed)
helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace \
  --set mig.strategy=mixed

# Upgrade GPU Operator
helm upgrade gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator

# Check GPU Operator pods
kubectl get pods -n gpu-operator

# Verify GPU node labels
kubectl get nodes -o json | jq '.items[].metadata.labels | to_entries[] | select(.key | startswith("nvidia"))'

# Check GPU resource availability
kubectl get nodes -o json | jq '.items[] | .metadata.name, .status.allocatable["nvidia.com/gpu"]'

# Check whether GPU node label is present
kubectl get nodes --show-labels | grep nvidia.com/gpu.present

# Describe a GPU node
kubectl describe node my-gpu-node | grep -A 10 "nvidia"

# Example Pod requesting 1 GPU
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: my-gpu-pod
  namespace: my-namespace
spec:
  containers:
  - name: my-model
    image: nvcr.io/nvidia/cuda:12.4.1-base-ubuntu22.04
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/gpu: 1
  restartPolicy: Never
EOF

# --- Time-slicing (GPU sharing) ---
# Create time-slicing ConfigMap
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: time-slicing-config
  namespace: gpu-operator
data:
  any: |-
    version: v1
    flags:
      migStrategy: none
    sharing:
      timeSlicing:
        resources:
        - name: nvidia.com/gpu
          replicas: 4
EOF

# Patch GPU Operator to use time-slicing config
kubectl patch clusterpolicies.nvidia.com cluster-policy \
  -n gpu-operator \
  --type merge \
  -p '{"spec":{"devicePlugin":{"config":{"name":"time-slicing-config","default":"any"}}}}'
```

---

## NVIDIA NIM (Inference Microservices)

```bash
# Set NGC API key
export NGC_API_KEY=<your-ngc-api-key>

# Log in to NGC container registry
echo "$NGC_API_KEY" | docker login nvcr.io \
  --username '$oauthtoken' \
  --password-stdin

# Pull a NIM container (example: Meta Llama 3.1 8B)
docker pull nvcr.io/nim/meta/llama-3.1-8b-instruct:1.1.2

# Run NIM with GPU (default port 8000)
docker run -d \
  --name my-nim \
  --gpus all \
  -e NGC_API_KEY=$NGC_API_KEY \
  -p 8000:8000 \
  -v /home/user/.cache/nim:/opt/nim/.cache \
  nvcr.io/nim/meta/llama-3.1-8b-instruct:1.1.2

# Health check – wait for NIM to be ready
curl http://localhost:8000/v1/health/ready

# List available models via OpenAI-compatible API
curl http://localhost:8000/v1/models | jq .

# Inference – chat completion (OpenAI-compatible)
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta/llama-3.1-8b-instruct",
    "messages": [{"role": "user", "content": "What is a GPU?"}],
    "max_tokens": 256
  }' | jq .

# View NIM container logs
docker logs -f my-nim

# Stop and remove NIM container
docker rm -f my-nim

# --- NIM on Kubernetes (Helm) ---
helm repo add nvidia https://helm.ngc.nvidia.com/nim
helm repo update

# Install NIM for Llama 3.1 8B
helm install my-nim nvidia/nim-llm \
  --namespace my-namespace \
  --create-namespace \
  --set model.name=meta/llama-3.1-8b-instruct \
  --set ngcSecret.apiKey=$NGC_API_KEY \
  --set resources.limits."nvidia\.com/gpu"=1

# Check NIM pod status
kubectl get pods -n my-namespace -l app=my-nim

# Port-forward NIM service for local testing
kubectl port-forward svc/my-nim 8000:8000 -n my-namespace
```

---

## Triton Inference Server

```bash
# Pull Triton container from NGC
docker pull nvcr.io/nvidia/tritonserver:24.05-py3

# Start Triton with a model repository
docker run -d \
  --name my-triton \
  --gpus all \
  -p 8000:8000 \
  -p 8001:8001 \
  -p 8002:8002 \
  -v /path/to/model-repository:/models \
  nvcr.io/nvidia/tritonserver:24.05-py3 \
  tritonserver --model-repository=/models

# Model repository layout
# /models
# └── my-model
#     ├── 1
#     │   └── model.pt          # versioned model artifact
#     └── config.pbtxt          # model configuration

# Example config.pbtxt for a PyTorch model
cat > /path/to/model-repository/my-model/config.pbtxt <<EOF
name: "my-model"
backend: "pytorch_libtorch"
max_batch_size: 8
input [
  {
    name: "INPUT__0"
    data_type: TYPE_FP32
    dims: [ 3, 224, 224 ]
  }
]
output [
  {
    name: "OUTPUT__0"
    data_type: TYPE_FP32
    dims: [ 1000 ]
  }
]
dynamic_batching {
  preferred_batch_size: [ 4, 8 ]
  max_queue_delay_microseconds: 100
}
EOF

# Check Triton server health
curl http://localhost:8000/v2/health/ready

# List loaded models
curl http://localhost:8000/v2/models | jq .

# Get model metadata
curl http://localhost:8000/v2/models/my-model | jq .

# Run performance analysis with perf_analyzer
docker run --rm \
  --net host \
  nvcr.io/nvidia/tritonserver:24.05-py3 \
  perf_analyzer \
    -m my-model \
    -u localhost:8001 \
    --concurrency-range 1:4 \
    -i grpc

# Python tritonclient – HTTP inference
pip install tritonclient[http]

python3 - <<EOF
import tritonclient.http as httpclient
import numpy as np

client = httpclient.InferenceServerClient(url="localhost:8000")

# Check server liveness
print("Live:", client.is_server_live())

# Prepare input
input_data = np.random.randn(1, 3, 224, 224).astype(np.float32)
inputs = [httpclient.InferInput("INPUT__0", input_data.shape, "FP32")]
inputs[0].set_data_from_numpy(input_data)

outputs = [httpclient.InferRequestedOutput("OUTPUT__0")]
result = client.infer("my-model", inputs, outputs=outputs)
print(result.as_numpy("OUTPUT__0").shape)
EOF

# Python tritonclient – gRPC inference
pip install tritonclient[grpc]

python3 - <<EOF
import tritonclient.grpc as grpcclient
import numpy as np

client = grpcclient.InferenceServerClient(url="localhost:8001")
input_data = np.random.randn(1, 3, 224, 224).astype(np.float32)
inputs = [grpcclient.InferInput("INPUT__0", input_data.shape, "FP32")]
inputs[0].set_data_from_numpy(input_data)
outputs = [grpcclient.InferRequestedOutput("OUTPUT__0")]
result = client.infer("my-model", inputs, outputs=outputs)
print(result.as_numpy("OUTPUT__0").shape)
EOF

# View Triton logs
docker logs -f my-triton
```

---

## MIG – Multi-Instance GPU

```bash
# --- Prerequisites ---
# Enable MIG mode (requires A100/H100/H200)
sudo nvidia-smi -i 0 -mig 1

# Confirm MIG mode is enabled
nvidia-smi --query-gpu=index,name,mig.mode.current --format=csv

# --- MIG Instance Management ---
# List available MIG GPU Instance Profiles (GIPs)
nvidia-smi mig -lgip

# Common profiles on A100 80GB:
# 1g.10gb   – 1/7 slice,  10 GB
# 2g.20gb   – 2/7 slices, 20 GB
# 3g.40gb   – 3/7 slices, 40 GB
# 7g.80gb   – full GPU,   80 GB

# Create a GPU Instance (gi) using profile ID (get ID from -lgip)
sudo nvidia-smi mig -cgi 9,9 -i 0        # two 1g.10gb slices on GPU 0

# List GPU Instances
nvidia-smi mig -lgi

# Create Compute Instances (ci) on each GPU Instance
sudo nvidia-smi mig -cci -i 0

# List all MIG devices (GPU Instances + Compute Instances)
nvidia-smi -L

# List Compute Instances
nvidia-smi mig -lci

# List MIG devices with memory info
nvidia-smi mig -lme

# Delete a specific Compute Instance (ci 0 on gi 0 on GPU 0)
sudo nvidia-smi mig -dci -ci 0 -gi 0 -i 0

# Delete a specific GPU Instance
sudo nvidia-smi mig -dgi -gi 0 -i 0

# Delete all MIG instances on GPU 0
sudo nvidia-smi mig -dci -i 0
sudo nvidia-smi mig -dgi -i 0

# Disable MIG mode (after deleting all instances)
sudo nvidia-smi -i 0 -mig 0

# --- MIG in Kubernetes (GPU Operator) ---
# Single strategy: all GPUs use same MIG profile
helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace \
  --set mig.strategy=single

# Mixed strategy: different profiles per node
helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace \
  --set mig.strategy=mixed

# Label node with desired MIG config (single strategy)
kubectl label node my-gpu-node \
  nvidia.com/mig.config=all-1g.10gb \
  --overwrite

# Example MIG resource request in a Pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: my-mig-pod
  namespace: my-namespace
spec:
  containers:
  - name: my-model
    image: nvcr.io/nvidia/cuda:12.4.1-base-ubuntu22.04
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/mig-1g.10gb: 1   # request one 1g.10gb MIG slice
  restartPolicy: Never
EOF
```

---

## NVIDIA AI Enterprise on Kubernetes

```bash
# --- NeMo (Large Language Model Training/Fine-tuning) ---
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

# Install NeMo Framework (training workloads)
helm install my-nemo nvidia/nemo \
  --namespace my-namespace \
  --create-namespace \
  --set image.repository=nvcr.io/nvidia/nemo \
  --set image.tag=24.05

# --- Riva (Speech AI – ASR/TTS/NLP) ---
# Pull Riva Quick Start scripts
ngc registry resource download-version \
  nvidia/riva/riva_quickstart:2.16.0

# Initialize and start Riva (downloads models + starts services)
bash riva_init.sh
bash riva_start.sh

# Riva speech API health
curl http://localhost:8000/v1/health/ready

# --- RAPIDS (GPU-accelerated Data Science) ---
# Run RAPIDS container
docker run --rm \
  --gpus all \
  -p 8888:8888 \
  -p 8787:8787 \
  nvcr.io/nvidia/rapidsai/base:24.04-cuda12.2-py3.11 \
  jupyter lab --ip=0.0.0.0 --no-browser --allow-root

# --- BioNeMo (Computational Biology) ---
# Pull BioNeMo container
docker pull nvcr.io/nvidia/clara/bionemo-framework:1.7

# --- GPU Sharing Strategies ---
# 1. Time-slicing (software-level, no memory isolation)
# Use ConfigMap + GPU Operator patch (see GPU Operator section)

# 2. MIG (hardware-level isolation, A100/H100 only)
# Enable MIG mode and create slices (see MIG section)

# 3. MPS (Multi-Process Service – shared CUDA context)
sudo nvidia-cuda-mps-control -d           # start MPS daemon
echo quit | sudo nvidia-cuda-mps-control  # stop MPS daemon
nvidia-smi --query-compute-apps=pid --format=csv  # verify

# --- nvidia-device-plugin ConfigMap (time-slicing) ---
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nvidia-device-plugin-config
  namespace: gpu-operator
data:
  config: |
    version: v1
    sharing:
      timeSlicing:
        renameByDefault: false
        failRequestsGreaterThanOne: false
        resources:
        - name: nvidia.com/gpu
          replicas: 4
EOF
```

---

## Monitoring & Observability

```bash
# --- DCGM Exporter (Prometheus metrics) ---
# Run DCGM Exporter as a container
docker run -d \
  --name dcgm-exporter \
  --gpus all \
  --cap-add SYS_ADMIN \
  -p 9400:9400 \
  nvcr.io/nvidia/k8s/dcgm-exporter:3.3.5-3.4.0-ubuntu22.04

# Check exported metrics
curl http://localhost:9400/metrics | grep DCGM_FI_DEV_GPU_UTIL

# Deploy DCGM Exporter via Helm (part of GPU Operator or standalone)
helm repo add gpu-helm-charts https://nvidia.github.io/dcgm-exporter/helm-charts
helm install dcgm-exporter gpu-helm-charts/dcgm-exporter \
  --namespace monitoring \
  --create-namespace

# --- Key DCGM / Prometheus Metrics ---
# GPU utilization (%)
# DCGM_FI_DEV_GPU_UTIL

# Memory copy (PCIe/NVLink) utilization (%)
# DCGM_FI_DEV_MEM_COPY_UTIL

# GPU memory used (MiB)
# DCGM_FI_DEV_FB_USED

# GPU memory free (MiB)
# DCGM_FI_DEV_FB_FREE

# GPU power usage (W)
# DCGM_FI_DEV_POWER_USAGE

# GPU temperature (°C)
# DCGM_FI_DEV_GPU_TEMP

# SM clock frequency (MHz)
# DCGM_FI_DEV_SM_CLOCK

# NVLink bandwidth (MB/s Tx/Rx)
# DCGM_FI_DEV_NVLINK_BANDWIDTH_TOTAL

# GPU ECC single-bit errors
# DCGM_FI_DEV_ECC_SBE_VOL_TOTAL

# GPU ECC double-bit errors
# DCGM_FI_DEV_ECC_DBE_VOL_TOTAL

# --- dcgmi CLI ---
# List all GPUs via DCGM
dcgmi discovery -l

# Start DCGM host engine
dcgmi hostengine --start

# Live monitoring with dcgmi
dcgmi dmon -e 203,204,1004,1005 -d 1000
# Field IDs: 203=GPU_UTIL 204=MEM_COPY_UTIL 1004=FB_USED 1005=POWER_USAGE

# Query GPU health
dcgmi health -g 1 -c

# --- Grafana Dashboard ---
# Import NVIDIA GPU dashboard from NGC (Grafana ID: 12239)
# In Grafana: Dashboards → Import → ID: 12239

# GPU topology map
nvidia-smi topo -m

# --- NVML Python Bindings ---
pip install nvidia-ml-py

python3 - <<EOF
import pynvml

pynvml.nvmlInit()
device_count = pynvml.nvmlDeviceGetCount()
print(f"GPUs detected: {device_count}")

for i in range(device_count):
    handle = pynvml.nvmlDeviceGetHandleByIndex(i)
    name   = pynvml.nvmlDeviceGetName(handle)
    mem    = pynvml.nvmlDeviceGetMemoryInfo(handle)
    util   = pynvml.nvmlDeviceGetUtilizationRates(handle)
    print(f"GPU {i}: {name}")
    print(f"  Memory: {mem.used // 1024**2} MiB used / {mem.total // 1024**2} MiB total")
    print(f"  Utilization: GPU {util.gpu}% | Memory {util.memory}%")

pynvml.nvmlShutdown()
EOF
```

---

## Tips & Tricks

```bash
# Limit CUDA to specific GPU(s) by index (avoids --gpus flag)
export CUDA_VISIBLE_DEVICES=0         # only GPU 0
export CUDA_VISIBLE_DEVICES=0,2       # GPUs 0 and 2
export CUDA_VISIBLE_DEVICES=""        # disable all GPUs

# Run single command with specific GPU
CUDA_VISIBLE_DEVICES=1 python my-model/train.py

# Persistence mode: keep driver loaded for faster initialization
sudo nvidia-smi -pm 1

# GPU burn stress test (validate GPU stability)
# https://github.com/wilicc/gpu-burn
docker run --rm --gpus all \
  nvcr.io/nvidia/cuda:12.4.1-base-ubuntu22.04 \
  bash -c "apt-get install -y gpu-burn && gpu_burn 60"

# Check CUDA version (from toolkit)
nvcc --version

# Check CUDA version (from runtime library)
cat /usr/local/cuda/version.json

# Check cuDNN version
cat /usr/include/cudnn_version.h | grep "#define CUDNN_MAJOR\|MINOR\|PATCHLEVEL"

# Or via Python
python3 -c "import torch; print(torch.backends.cudnn.version())"

# Enable TF32 for faster FP32 on Ampere GPUs (PyTorch)
export NVIDIA_TF32_OVERRIDE=1

# Container env vars for maximum performance
# NCCL (multi-GPU / multi-node communication)
export NCCL_DEBUG=INFO
export NCCL_IB_DISABLE=0           # use InfiniBand if available
export NCCL_P2P_DISABLE=0          # enable P2P transfers
export NCCL_SOCKET_IFNAME=eth0     # specify network interface

# Flash Attention env vars
export FLASH_ATTENTION_FORCE_BUILD=TRUE

# Triton autotuning cache
export TRITON_CACHE_DIR=/tmp/triton-cache

# NGC Catalog URL (browse models, containers, datasets)
# https://catalog.ngc.nvidia.com

# NIM Catalog URL (discover NIM microservices)
# https://build.nvidia.com

# Quick NGC model shortcuts (commonly used)
# PyTorch base image:       nvcr.io/nvidia/pytorch:24.05-py3
# TensorFlow base image:    nvcr.io/nvidia/tensorflow:24.05-tf2-py3
# CUDA base image:          nvcr.io/nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04
# NeMo framework:           nvcr.io/nvidia/nemo:24.05
# Triton server:            nvcr.io/nvidia/tritonserver:24.05-py3
# Llama-3.1-8B NIM:         nvcr.io/nim/meta/llama-3.1-8b-instruct:latest
# Mistral-7B NIM:           nvcr.io/nim/mistralai/mistral-7b-instruct-v0.3:latest

# Useful kubectl aliases for GPU workflows
alias kgpu='kubectl get pods -A | grep -i gpu'
alias klogs-nim='kubectl logs -f -l app=my-nim -n my-namespace'
alias kdesc-node='kubectl describe nodes | grep -A 5 "nvidia\|gpu"'

# Check GPU Operator version
helm list -n gpu-operator -o json | jq '.[].app_version'

# Watch GPU Operator pods until all are Running
watch kubectl get pods -n gpu-operator
```
