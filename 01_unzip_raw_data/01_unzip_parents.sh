#!/usr/bin/env bash
# 
# Unzip the tarballs containing raw data for the parents.
#
# Tom Ellis
# 2026-02-03

# SLURM
#SBATCH --job-name=01_unzip_parents
#SBATCH --output=%x.out
#SBATCH --error=%x.err
#SBATCH --qos=short
#SBATCH --time=2:00:00

# Set working directory
source setup.sh

# === Input === #

# Paths to tarballs containing raw fastq files.
# 1137 and 1074
tarball_missing=/resources/ngs/nordborg/18523/22YHLCLT3_4_R18523_20250303.tar.gz
# 1435, 5835, 6199, 992, 1318, 9399, 6043
tarball_wrong_or_contaminated=/resources/ngs/nordborg/19911/237JJJLT3_1_R19911_20251213.tar.gz


# === Output === #

# Output directories
outdir=01_unzip_raw_data/01_unzip_parents
mkdir -p $outdir

# A single directory to store subdirectories with raw files for each plate
# This removes the complicated file paths in the unzipped tarballs
mkdir $outdir/plate_directories

# === Main === #

# Extract files for 1137 and 1074
tar -xf $tarball_missing -C $outdir 

# # Extract the other files.
tar -xf $tarball_wrong_or_contaminated -C $outdir 

# Move directories of data files to a single superdirectory
mv $outdir/*/demultiplexed/3* $outdir/plate_directories

