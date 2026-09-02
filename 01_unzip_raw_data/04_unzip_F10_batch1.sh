#!/usr/bin/env bash
# 
# Unpack tarballs of raw sequence data for the F10 batch 1 data.
#
# Tom Ellis
# 2026-01-23

# SLURM
#SBATCH --job-name=04_unzip_F10_batch1
#SBATCH --output=%x-%a.out
#SBATCH --error=%x-%a.err
#SBATCH --qos=short
#SBATCH --time=2:00:00
#SBATCH --array 0-2

# Set working directory
source setup.sh

# === Input === #

i=$SLURM_ARRAY_TASK_ID

# Path with tarballed data
indir=/groups/nordborg/projects/crosses/tom/01_data/12_F10_ngs_data/


# === Output === #

# Output directories
outdir=01_unzip_raw_data/04_unzip_F10_batch1
mkdir -p $outdir

# A single directory to store subdirectories with raw files for each plate
# This removes the complicated file paths in the unzipped directories
mkdir $outdir/plate_directories


# === Main === #

files=($indir/*tar.gz)
echo "File to unzip: ${files[$i]}"

# Check if the file exists
infile=${files[$SLURM_ARRAY_TASK_ID]}
if test -f "$infile"; then
    echo "$infile exists."
fi

# Unzip raw data to the working directory
tar -xzf $infile --directory  ${outdir}

# Move directories of data files to a single superdirectory
mv $outdir/*/demultiplexed/3* $outdir/plate_directories