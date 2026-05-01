#!/bin/bash
set -e  # exit on any error

# Build with: docker build --progress=plain -t bindcraft:test .
################## BindCraft installation script 
################## Tested on 2025-09-04

# Hardcoded config
pkg_manager="mamba"   # or "conda" if you prefer
#For RTX6000, L40, L40S, A40 use: cuda="12.1"
#For A100 use: cuda="11.8"
CUDA_VERSION="12.1"

############################################################################################################
################## Initialization
SECONDS=0
install_dir=$(pwd)

# Check conda installation
CONDA_BASE=$(conda info --base 2>/dev/null) || { echo "Error: conda not installed or not initialised"; exit 1; }
echo "Conda is installed at: $CONDA_BASE"

############################################################################################################
################## Create BindCraft environment
echo "Creating BindCraft environment"
$pkg_manager create --name BindCraft python=3.10 -y || { echo "Error: Failed to create BindCraft env"; exit 1; }

# Activate environment
echo "Activating BindCraft environment"
source ${CONDA_BASE}/bin/activate ${CONDA_BASE}/envs/BindCraft
[ "$CONDA_DEFAULT_ENV" = "BindCraft" ] || { echo "Error: BindCraft environment not active"; exit 1; }
echo "BindCraft environment activated at ${CONDA_BASE}/envs/BindCraft"

############################################################################################################
################## Install conda requirements
echo "Removing problematic conda channels"
conda config --env --remove channels https://conda.graylab.jhu.edu 2>/dev/null || true

echo "Installing conda packages"
# Split into two steps to avoid dependency conflicts
$pkg_manager install \
  pip pandas matplotlib 'numpy<2.0.0' biopython scipy pdbfixer seaborn libgfortran5 tqdm \
  jupyter jupyterlab ipywidgets ffmpeg fsspec py3dmol psutil copyparty \
  nodejs -c conda-forge -y \
|| { echo "Error: Failed to install conda packages"; exit 1; }

echo "Installing JAX/ML conda packages"
$pkg_manager install \
  chex dm-haiku dm-tree joblib ml-collections immutabledict optax \
  -c conda-forge -y \
|| { echo "Error: Failed to install ML packages"; exit 1; }


# ===============================
# JupyterLab / ipywidgets fix
# ===============================
echo "[STEP] Fixing JupyterLab widget extensions..."

# Clean any old builds
jupyter lab clean

# Rebuild lab to include ipywidgets JS
jupyter lab build

echo "[INFO] JupyterLab widget extensions rebuilt and notebook trusted"

############################################################################################################
################## Install pip requirements
echo "Installing pip packages"
python -m pip install --upgrade pip wheel jupyter-server-proxy

if [ "$CUDA_VERSION" = "12.1" ]; then
    python -m pip install --no-cache-dir \
      jax==0.4.28 \
      jaxlib==0.4.28+cuda12.cudnn89 \
      -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html --no-deps

elif [ "$CUDA_VERSION" = "11.8" ]; then
python -m pip install --no-cache-dir \
  jax==0.4.20 \
  jaxlib==0.4.20+cuda11.cudnn86 \
  -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html --no-deps

else
    echo "[WARN] Unsupported CUDA version for JAX installation"
fi
# install nvidia-ml-py3 for GPU monitoring
python -m pip install nvidia-ml-py3

############################################################################################################
################## Install PyRosetta
echo "Installing PyRosetta from direct package URL"
PYROSETTA_PACKAGE_URL="https://conda.rosettacommons.org/linux-64/rosetta-2025.03+release.1f5080a079-0.tar.bz2"
PYROSETTA_PACKAGE_NAME=$(basename "$PYROSETTA_PACKAGE_URL")
PYROSETTA_TEMP_DIR="/tmp/pyrosetta_install"

mkdir -p "$PYROSETTA_TEMP_DIR"
cd "$PYROSETTA_TEMP_DIR"

echo "Downloading PyRosetta package..."
wget -O "$PYROSETTA_PACKAGE_NAME" "$PYROSETTA_PACKAGE_URL" || { echo "Error: Failed to download PyRosetta"; exit 1; }

echo "Installing PyRosetta package using conda..."
# Use conda/mamba's internal package installation mechanism
conda package -w "$PYROSETTA_PACKAGE_NAME" || {
    echo "Package validation not available, proceeding with manual extraction..."
}

# Extract to a temporary location to examine structure
mkdir -p extracted
tar -xjf "$PYROSETTA_PACKAGE_NAME" -C extracted/

# Copy all contents to the conda environment
echo "Copying PyRosetta files to conda environment..."
cp -r extracted/* "${CONDA_BASE}/envs/BindCraft/" || { echo "Error: Failed to copy PyRosetta files"; exit 1; }

# Verify installation
echo "Verifying PyRosetta installation..."
python -c "import pyrosetta; print('PyRosetta version:', pyrosetta.__version__ if hasattr(pyrosetta, '__version__') else 'imported successfully')" || {
    echo "Error: PyRosetta not importable after installation"
    echo "Checking what was extracted:"
    ls -la extracted/
    exit 1
}

cd "$install_dir"
rm -rf "$PYROSETTA_TEMP_DIR"
echo "PyRosetta installation complete"

############################################################################################################
################## Install ColabDesign
# install ColabDesign
echo -e "Installing ColabDesign\n"
python -m pip install git+https://github.com/sokrypton/ColabDesign.git --no-deps || { echo -e "Error: Failed to install ColabDesign"; exit 1; }
python -c "import colabdesign" >/dev/null 2>&1 || { echo -e "Error: colabdesign module not found after installation"; exit 1; }

############################################################################################################
################## Fix permissions for executables
chmod +x "${install_dir}/functions/dssp" || { echo "chmod dssp failed"; exit 1; }
chmod +x "${install_dir}/functions/DAlphaBall.gcc" || { echo "chmod DAlphaBall.gcc failed"; exit 1; }

############################################################################################################
################## Cleanup
conda deactivate
echo "Cleaning up ${pkg_manager} cache"
$pkg_manager clean -a -y

############################################################################################################
################## Finish
t=$SECONDS 
echo -e "\nSuccessfully finished BindCraft installation!"
echo "Activate environment: $pkg_manager activate BindCraft"
echo "Installation took $(($t / 3600))h $((($t / 60) % 60))m $(($t % 60))s"
