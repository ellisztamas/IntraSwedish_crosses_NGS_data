#!/usr/bin/env bash
# 
# Unpack tarballs of raw sequence data for the low-coverage F8 data.
#
# Tom Ellis
# 2025-03-25.

# SLURM
#SBATCH --job-name=03_unzip_F8_highcov
#SBATCH --output=%x-%a.out
#SBATCH --error=%x-%a.err
#SBATCH --mem=1GB
#SBATCH --qos=short
#SBATCH --time=2:00:00


# Set working directory
source setup.sh

# === Input ===

# Path with tarballed data
infile=/groups/nordborg/projects/crosses/tom/01_data/08_resequenced_F8s/22YHLCLT3_4_R18523_20250303.tar.gz



# === Output ===

# Output directories
outdir=01_unzip_raw_data/03_unzip_highcov_F8
mkdir -p $outdir



# === Main ===

# Unzip raw data to the working directory
tar -xzf $infile --directory  ${outdir}