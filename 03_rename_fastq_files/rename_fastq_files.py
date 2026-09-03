#!/usr/bin/env python3

'''
Rename fastq file with informative names.

For each sequencing batch separately, import the input sample sheet and pull out
three columns:

* `source_fastq_R1` and `source_fastq_R2` contain paths to files with raw names
* `target_fastq_R1` and `target_fastq_R2` contain paths to copy and rename those files to.

Files from the source columns are copied and renamed to the corresponding targets.

The copying is done in series, so consider running this inside a tmux window or similar.

Tom Ellis
2026-09-03
'''

from pathlib import Path
import shutil
import pandas as pd


def copy_fastq_files(path_to_input_sheet: str) -> None:
    """
    Import a TSV file and copy FASTQ files specified by source/target path columns.

    Required columns:
        - source_fastq_R1
        - source_fastq_R2
        - target_fastq_R1
        - target_fastq_R2

    Target parent directories are created automatically when needed.
    """
    df = pd.read_csv(path_to_input_sheet, sep='\t')

    required_columns = {
        "source_fastq_R1",
        "source_fastq_R2",
        "target_fastq_R1",
        "target_fastq_R2",
    }
    missing_columns = required_columns - set(df.columns)
    if missing_columns:
        raise ValueError(f"Missing required columns: {sorted(missing_columns)}")
    
    for row_index, row in df.iterrows():
        file_pairs = [
            (row["source_fastq_R1"], row["target_fastq_R1"]),
            (row["source_fastq_R2"], row["target_fastq_R2"]),
        ]

        for source, target in file_pairs:
            source_path = Path(source)
            target_path = Path(target)

            if not source_path.is_file():
                raise FileNotFoundError(
                    f"Source file not found at row {row_index}: {source_path}"
                )
            
            target_path.parent.mkdir(parents=True, exist_ok=True)
            print(f"Copying {source_path} -> {target_path}")
            shutil.copy2(source_path, target_path)



copy_fastq_files("02_input_sample_sheets/parents_input_sheet.tsv")
copy_fastq_files("02_input_sample_sheets/F8_lowcov_input_sheet.tsv")
copy_fastq_files("02_input_sample_sheets/F8_highcov_input_sheet.tsv")
copy_fastq_files("02_input_sample_sheets/F10_batch1_input_sheet.tsv")