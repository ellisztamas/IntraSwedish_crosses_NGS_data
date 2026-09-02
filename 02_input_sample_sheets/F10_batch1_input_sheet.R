#' Script to create an input sample sheet for F8 high-coverage sequencing batch.
#' 
#' This script creates a character variable that concatenates the
#' expected path to each sample's raw R1 data file(s) and the first part of each 
#' file name (the NGS request ID and two indices) then greps those partial paths
#' in a list of actual unzipped filenames. 
#' It identifies R2 files by string substitution.
#' It then confirms that these files exist, and that there are no duplicates.
#' 
#' Tom Ellis
#' 2026-09-02


library(tidyverse)

# Import a lab sample sheet giving well positions, legacy line names, and 
# sequencing indices.
f10_batch1 <- read_csv(
  "../tom/01_data/12_F10_ngs_data/F10_genotyping_sample_sheet.csv"#, col_types = 'ccccccc'
)

f10_batch1 <- f10_batch1 %>% 
  rename(
    line = sample,
    legacy_line_name = genotype
  ) %>% 
  mutate(
    sample_alias = paste0(line, "_F10batch1"),
    collection_date = "2024-11-04",
    library_name = paste0("33", row, col),
    target_fastq_R1 = paste("03_rename_fastq_files/F10_batch1/", sample_alias, library_name, "run1_R1.fastq.gz", sep ="_"),
    target_fastq_R2 = paste("03_rename_fastq_files/F10_batch1/", sample_alias, library_name, "run1_R2.fastq.gz", sep ="_"),
    to_grep = paste0(directory, "_", index1, index2)
  )

# Line up the sample and file names by grepping the NGS indices against a list of file names
# Do this for R1 files only.
path_prefix <- "01_unzip_raw_data/04_unzip_F10_batch1/plate_directories"
fastq_R1_paths <- list.files(path = path_prefix, pattern = "_R1_001.fastq\\.gz$", recursive = TRUE, full.names = TRUE)
# Grep each sample one at a time, and check they only appear once and only once.
f10_batch1$source_fastq_R1 <- NA
for(i in 1:nrow(f10_batch1)){
  path_match <- grep(f10_batch1$to_grep[i], fastq_R1_paths, value=TRUE)
  if(length(path_match) == 0) {
    warning("This path was not found:\n", f10_batch1$to_grep[i])
    path_match <- NA
  }
  if(length(path_match) >  1) {
    stop("This path was found more than once:\n", f10_batch1$to_grep[i])
  }
  f10_batch1$source_fastq_R1[i] <- path_match
}


# All samples have a R1 file
f10_batch1[is.na(f10_batch1$source_fastq_R1),]

# Identify the R2 files by string subsitution
f10_batch1 <- f10_batch1 %>%
  mutate(
    source_fastq_R2 = gsub("_R1_", "_R2_", source_fastq_R1)
  )

# Double check the entries are all unique
all(table(f10_batch1$source_fastq_R1) == 1)
all(table(f10_batch1$source_fastq_R2) == 1)
# Check all the files exist on disk
all(file.exists(f10_batch1$source_fastq_R1))
all(file.exists(f10_batch1$source_fastq_R2))


# Arrange the columns and write to disk
f10_batch1 %>%
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
  ) %>% 
  arrange(sample_alias) %>% 
  write_tsv(
    "02_input_sample_sheets/F10_batch1_input_sheet.tsv"
  )

