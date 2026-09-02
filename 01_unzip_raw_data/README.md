# Scripts to unzip tarballs

These scripts unzip tarballs containing the raw fastq files (among other files) from the VBC server.

These scripts output a directory of unzipped tarballs for each sequencing batch.
Paths to individual fastq files inside those directories are referenced in the input sample sheets under columns `source_fastq_R1` and `source_fastq_R2`

These tarballs are not accessible outside of VBC, so these scripts will not run on other machines.
They are included here for transparency and completeness.