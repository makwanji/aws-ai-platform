# Overview

This project demonstrates how to build a GPU-accelerated AI training cluster on AWS using Kubernetes and SLURM.

## Architecture

## Infrastructure Components

| Layer                   | Technology          |
| ----------------------- | ------------------- |
| Compute                 | GPU EC2 nodes       |
| Scheduling              | SLURM               |
| Container orchestration | Kubernetes          |
| GPU lifecycle           | NVIDIA GPU Operator |
| Monitoring              | DCGM + Prometheus   |
| Storage                 | FSx Lustre          |

## Example AI Job

```bash
sbatch train.sh
```

## Screenshots

- nvidia-smi
- Grafana dashboard
- SLURM job queue
