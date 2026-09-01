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

* `fastq1` and `fastq2` are paths to fastq files with raw names from the NGS facility.
* `basename` gives the (most of) the target file name for each fastq file.
    * This will be appended with `_R1.fastq.gz` and `_R2,fastq.gz`.
* `file_name1` and `file_name2` are file names for each fastq file, after renaming.
    * This is used to create the checksums and Reads sample sheets.
    * This is obviously redundant with `basename`.
* Columns needed to create the **Samples** submission sheets:
    * `sample_alias`: The unique name for the biological sample.
        * In most cases, each sample was only sequenced once, so this should be unique
        * The exception is the F8 low coverage batch, which were sequenced over two lanes.
    * `alias`: Line name.
        * For parental lines, this is ecotype ID.
        * For crossed lines, this is the line ID, starting with `ISC`
    * `collection date`: Date on which tissue was collected. In practice this is often date the library was submitted, because I don't have information on collection date.
* Columns needed to create the **Reads** submission sheets:
    * TBC once I go through the reads submission script.

The other columns are not essential, and are mostly there to set up the sheet.
