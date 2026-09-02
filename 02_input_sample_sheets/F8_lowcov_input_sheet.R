#' Script to create an input sample sheet for F8 low coverage sequencing batch.
#' 
#' This is a complciated example, because data were sequenced across five plates,
#' but plates 1-4 were run on two flow cells, so there are two pairs of files
#' in different directories for each sample, which breaks my usual workflow for
#' sorting raw files.
#' 
#' Instead, this script creates a character variable that concatenates the
#' expected path to each sample's raw R1 data file(s) and the first part of each 
#' file name (the NGS request ID and two indices) then greps those partial paths
#' in a list of actual unzipped filenames. 
#' It identifies R2 files by string substitution.
#' It then confirms that these files exist, and that there are no duplicates.
#' 
#' Tom Ellis
#' 2026-08-14
  
  
library(tidyverse)
# Import a lab sample sheet giving well positions, legacy line names, and
# sequencing indices.
f8_lowcov <- read_csv(
  "../tom/01_data/02_F8_unaligned_bams/sequencing_plates_original.csv"
)

# This project originally used line names reflecting the expected cross parents (e.g. "1002x6038_rep1")
# However, I moved a a system of numbers (e.g. ISC_001.1), coupled with a table
# of genotypes, because some cross labels were found to be incorrect or ambiguous.
# Import a table giving the correspondence between legacy and updated line names.
line_ids <- read_tsv(
  "../tom/01_data/old_vs_new_names.tsv", col_types = 'cc'
)


# Remove two A. arenosa samples
f8_lowcov <- f8_lowcov %>%
  filter(!grepl("Aa1xAa2", sample))

# Join by legacy name
f8_lowcov <- f8_lowcov %>%
  mutate(
    generation = "F8",
    legacy_id = gsub("_F8_", "_", sample)
  ) %>%
  left_join(line_ids, by ='legacy_id') %>%
  rename(line=id, legacy_line_name = legacy_id) # to be consistent with other files.

# Fill in columns
f8_lowcov <- f8_lowcov %>%
  mutate(
    library_name = paste0(plate, row, col),
    flowcell = case_when(
      plate %in% 1:4 ~ 'H32TKDSX5',
      plate == 5 ~ 'HMN2MDRX2'
    ),
    collection_date = case_when(
      plate %in% 1:4 ~ '2022-12-03',
      plate == 5 ~ '2023-01-19'
    ),
    # NGS ID is an internal request ID from the VBC NGS facility
    ngs_id = case_when(
      plate == 1 ~ 216113,
      plate == 2 ~ 216110,
      plate == 3 ~ 216112,
      plate == 4 ~ 216111,
      plate == 5 ~ 219242
    ),
    instrument_model = "Illumina NovaSeq X",
    pooled = "individual plant",
    study = "PRJEB123735",
    experiment = paste0("plate",plate),
    sample_alias = paste(line, "F8lowcov", sep="_")
  )


# Create a variable giving the first part of the expected file name for each R1 file.
f8_lowcov <- rbind(
  # Samples in plates 1-4, on the first flowcell
    f8_lowcov %>%
    filter(plate %in% 1:4) %>%
    mutate(
      to_grep = paste0(ngs_id, "_", index1, index2,".*","L003"),
      run='run1'
    ),
  # Samples in plates 1-4, on the second flowcell
    f8_lowcov %>%
    filter(plate %in% 1:4) %>%
    mutate(
      to_grep = paste0(ngs_id, "_", index1, index2,".*","L004"),
      run='run2'
    ),
  # Samples from plate 5.
  f8_lowcov %>%
    filter(plate == 5) %>%
    mutate(
      to_grep = paste0(ngs_id, "_", index1, index2),
      run='run1'
    )
)


# Line up the sample and file names by grepping the NGS indices against a list of file names
# Do this for R1 files only.
path_prefix <- "01_unzip_raw_data/02_unzip_lowcov_F8"
fastq_R1_paths <- list.files(path = path_prefix, pattern = "_R1_001.fastq\\.gz$", recursive = TRUE, full.names = TRUE)
# Grep each sample one at a time, and check they only appear once and only once.
f8_lowcov$source_fastq_R1 <- NA
for(i in 1:nrow(f8_lowcov)){
  path_match <- grep(f8_lowcov$to_grep[i], fastq_R1_paths, value=TRUE)
  if(length(path_match) == 0) {
    warning("This path was not found:\n", f8_lowcov$to_grep[i])
    path_match <- NA
  }
  if(length(path_match) >  1) {
    stop("This path was found more than once:\n", f8_lowcov$to_grep[i])
  }
  f8_lowcov$source_fastq_R1[i] <- path_match
}

# Three samples don't have a file.
# Checking the lab management notes: Viktoria recorded these as having no library.
# This is the expected result.
f8_lowcov[is.na(f8_lowcov$source_fastq_R1),]
f8_lowcov <- f8_lowcov %>% filter(!is.na(f8_lowcov$source_fastq_R1))

# Identify the R2 files by string subsitution
f8_lowcov <- f8_lowcov %>%
  mutate(
    source_fastq_R2 = gsub("_R1_", "_R2_", source_fastq_R1)
  )

# Double check the entries are all unique
all(table(f8_lowcov$source_fastq_R1) == 1)
all(table(f8_lowcov$source_fastq_R2) == 1)
# Check all the files exist on disk
all(file.exists(f8_lowcov$source_fastq_R1))
all(file.exists(f8_lowcov$source_fastq_R2))


# Add target file names for the downstream fastq files, and get the columns to write
f8_lowcov <- f8_lowcov %>%
  mutate(
    basename   = paste0(sample_alias, "_", library_name,"_",run),
    target_fastq_R1 = paste0("03_rename_fastq_files/F8_low_cov/", basename,"_R1.fastq.gz"),
    target_fastq_R2 = paste0("03_rename_fastq_files/F8_low_cov/", basename,"_R2.fastq.gz")
  ) %>%
  select(
    line,
    legacy_line_name,
    sample_alias,
    library_name,
    collection_date,
    source_fastq_R1,
    source_fastq_R2,
    target_fastq_R1,
    target_fastq_R2,
  )


# Write to disk
f8_lowcov %>%
  arrange(sample_alias) %>% 
  write_tsv(
    "02_input_sample_sheets/F8_lowcov_input_sheet.tsv"
  )
