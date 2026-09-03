# Shell commands to generate md5 hashes for each sequencing cohort.
#
# This works on one input sample sheet at a time, and extracts paths to fastq
# files given in the columns `target_fastq_R1` and `target_fastq_R2`.
# It then spawns a job to run `md5sum` on each of those files in parallel.
#
# Important: this is set up to spawn jobs in parallel on via a SLURM scheduler
# for an HPC. Don't use sbatch, or try this inside an interactive session.
# Just run the commands as they are from a login node.
#
# This returns a directory for each input sheet containing a text file listing
# each file with its MD5 has.
# The directory will also contain log information and temororary files.
#
# Tom Ellis
# 2026-09-01


# path to the script to spwan jobs.
checksum_script=04_create_checksums/create_checksums.sh

# paths to input sample sheets
parents_input=02_input_sample_sheets/parents_input_sheet.tsv
F8_lowcov_input=02_input_sample_sheets/F8_lowcov_input_sheet.tsv
F8_highcov_input=02_input_sample_sheets/F8_highcov_input_sheet.tsv
F10_batch1_input=02_input_sample_sheets/F10_batch1_input_sheet.tsv

# paths to directories to store the md5 hashes, logs and temporary files.
parents_outdir=04_create_checksums/parents
F8_lowcov_outdir=04_create_checksums/F8_lowcov
F8_highcov_outdir=04_create_checksums/F8_highcov
F10_batch1_outdir=04_create_checksums/F10_batch1

# Run the jobs
bash $checksum_script $parents_input    $parents_outdir
bash $checksum_script $F8_lowcov_input  $F8_lowcov_outdir
bash $checksum_script $F8_highcov_input $F8_highcov_outdir
bash $checksum_script $F10_batch1_input $F10_batch1_outdir
