# Bindbot

A containerized protein binder design workflow combining [BindCraft](https://github.com/martinpacesa/BindCraft) with RunPod GPU cloud integration.

## Overview

This repository packages BindCraft's protein design tools into a Docker container optimized for cloud GPU deployment on RunPod. It provides a Jupyter-based GUI for simplified binder design workflows without local GPU requirements.

**Based on:**
- **BindCraft** by Martin Pacesa et al. - Automated protein binder design framework (MIT License)
- **RunPod Integration** by A-Yarrow - Cloud deployment wrapper with GUI for BindCraft

## Quick Start

Clone the repository:
```bash
git clone -b main https://github.com/LukeFord22/Bindbot.git
cd Bindbot
```

Build and push the Docker image:
```bash
docker build -t your-dockerhub-username/bindbot:latest .
docker push your-dockerhub-username/bindbot:latest
```

Deploy on RunPod with a compatible GPU (A100, H100, L40, L40S, RTX6000 Ada).

Access JupyterLab on port 8888 and use `bindbot-start.ipynb` to launch design jobs.

## Credits

- **BindCraft**: Martin Pacesa et al. - https://github.com/martinpacesa/BindCraft
- **ColabDesign**: Sergey Ovchinnikov (Apache 2.0)
- **ProteinMPNN**: Justas Dauparas (Apache 2.0)
- **PyRosetta**: RosettaCommons
- **RunPod Integration**: A-Yarrow - https://github.com/A-Yarrow/bindcraft-runpod

## License

This project reuses components from BindCraft (MIT License). See original repositories for full license details.