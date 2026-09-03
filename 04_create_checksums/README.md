# Generate md5 hashes for each sequencing cohort.

This directory contains two scripts to generate MD5 hashes for each fastq file.
This is needed as part of the ENA 'Reads' submission sheet.

This works on one input sample sheet at a time, and extracts paths to fastq
files given in the columns `target_fastq_R1` and `target_fastq_R2`.
It then spawns a job to run `md5sum` on each of those files in parallel.

However, `md5sum` is really slow to run in series over many files.
`create_checksums.sh` is a helper script to spawn jobs in parallel on via a
SLURM scheduler for an HPC.
`run_create_checksums.sh` gives commands to run it.

The scripts return a directory for each input sheet containing a text file listing
each file with its MD5 hash.
The directory will also contain log information and temororary files.

`create_checksums.sh`was drafted with the assistance of Abacus AI Agent (Abacus.AI, Inc.), an AI-powered coding assistant. The generated code was reviewed, tested, and modified by the authors prior to use.
