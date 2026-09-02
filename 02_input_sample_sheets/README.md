# Input sample sheets

This directory contains 'input' sample sheets, that are used to create the files necessary to create the additional files for the ENA submission.

There is one tab-delimited text file per sequencing batch (see the README in the top level directory for details of what those batches are).
Each file contains one row per pair of fastq files (i.e. a pair of R1 and R2 files) for a single run.
For the F8 low coverage cohort, plates 1-4 were sequenced over two lanes, so there are two rows per sample.

The information in these files contain information to

1. Rename the raw data files to informative names
2. Generate checksums for each raw data file
3. Create the ENA 'Samples' submission sheets
4. Create the ENA 'Reads' submission sheets

Key columns in each file:

* `line`: Line name.
* `legacy_line_name`: While developing the crosses, lines were assigned a name based on the parents of the cross. In fact, genotyping them revealed that some of the expected parents were wrong or ambigous, so I switched to the ISC names. I include the legacy names here for completeness, but you should in general not use them to indicate parentage robustly.
* `sample_alias`: The unique name for the biological sample.
    * In most cases, each sample was only sequenced once, so this should be unique
    * The exception is the F8 low coverage batch, which were sequenced over two lanes. 
* `library_name`: Samples were processed on 96-well plates, with one library per well.
* `collection date`: Date on which tissue was collected. In practice this is often date the library was submitted, because I don't have information on collection date.
* sample_alias	library_name	collection_date	source_fastq_R1	source_fastq_R2	target_fastq_R1	target_fastq_R2
* `source_fastq_R1` and `source_fastq_R2` are paths to fastq files with raw names from the NGS facility.
* `target_fastq_R1` and `target_fastq_R2` are paths to fastq files after they have been renamed with informative names. The basenames of these files are what will be uploaded to ENA.

See the [README on renaming files](../04_create_checksums/README.md) for more details.