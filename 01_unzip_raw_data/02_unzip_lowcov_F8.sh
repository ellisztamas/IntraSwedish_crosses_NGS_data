#!/usr/bin/env bash
# 
# Unpack tarballs of raw sequence data for the low-coverage F8 data.
#
# Tom Ellis
# 32026-08-31

# SLURM
#SBATCH --job-name=02_unzip_lowcov_F8
#SBATCH --output=%x-%a.out
#SBATCH --error=%x-%a.err
#SBATCH --mem=1GB
#SBATCH --qos=short
#SBATCH --time=2:00:00
#SBATCH --array 0-2

# Set working directory
source setup.sh

# === Input === #

# Path with tarballed data
indir=/groups/nordborg/projects/crosses/tom/01_data/02_F8_unaligned_bams


# === Output === #

# Output directories
outdir=01_unzip_raw_data/02_unzip_lowcov_F8
mkdir -p $outdir


# === Main === #

files=($indir/*tar.gz)
echo "File to unzip: ${files[$SLURM_ARRAY_TASK_ID]}"

# Check if the file exists
infile=${files[$SLURM_ARRAY_TASK_ID]}
if test -f "$infile"; then
    echo "$infile exists."
fi

# Unzip raw data to the working directory
tar -xzf $infile --directory  ${outdir}



