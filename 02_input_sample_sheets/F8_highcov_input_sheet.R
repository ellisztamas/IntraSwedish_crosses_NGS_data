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
f8_highcov <- read_csv(
  "../tom/01_data/08_resequenced_F8s/sample_sheet.csv", col_types = 'ccccccc'
)
# Import a table giving the correspondence between legacy and updated line names.
line_ids <- read_tsv(
  "../tom/01_data/old_vs_new_names.tsv", col_types = 'cc'
)


f8_highcov <- f8_highcov %>% 
  # Merge on legacy line name, and rename the new and old line names.
  left_join(line_ids, join_by(name == legacy_id)) %>% 
  rename(
    legacy_line_name = name,
    line = id
  ) %>% 
  # Remove two parental lines that were included in this plate, and three negative controls
  filter(!is.na(line))


# Create additional columns
f8_highcov <- f8_highcov %>% 
  mutate(
    sample_alias = paste0(line, "_F8highcov"),
    plate = "11",
    library_name = paste0(plate, row, col),
    collection_date = "2024-11-04",
    target_fastq_R1 = paste("03_rename_fastq_files/F8_highcov/", sample_alias, library_name, "run1_R1.fastq.gz", sep ="_"),
    target_fastq_R2 = paste("03_rename_fastq_files/F8_highcov/", sample_alias, library_name, "run1_R2.fastq.gz", sep ="_"),
    # concatenate the indices so they can be grepped against file names
    indices_to_grep = paste0(index1, index2)
  ) 


path_prefix <- "01_unzip_raw_data/03_unzip_highcov_F8"
fastq_R1_paths <- list.files(path = path_prefix, pattern = "_R1_001.fastq\\.gz$", recursive = TRUE, full.names = TRUE)

# Grep each sample one at a time, and check they only appear once and only once.
f8_highcov$source_fastq_R1 <- NA
for(i in 1:nrow(f8_highcov)){
  path_match <- grep(f8_highcov$indices_to_grep[i], fastq_R1_paths, value=TRUE)
  if(length(path_match) == 0) {
    warning("This path was not found:\n", f8_highcov$indices_to_grep[i])
    path_match <- NA
  }
  if(length(path_match) >  1) {
    stop("This path was found more than once:\n", f8_highcov$indices_to_grep[i])
  }
  f8_highcov$source_fastq_R1[i] <- path_match
}


na_rows <- f8_highcov[is.na(f8_highcov$source_fastq_R1),]
if(nrow(na_rows) > 0){
  warning("One or more samples have missing data files:\n")
  na_rows
}

# Identify the R2 files by string subsitution
f8_highcov <- f8_highcov %>%
  mutate(source_fastq_R2 = gsub("_R1_", "_R2_", source_fastq_R1))

# Double check the entries are all unique
all(table(f8_highcov$source_fastq_R1) == 1)
all(table(f8_highcov$source_fastq_R2) == 1)
# Check all the files exist on disk
all(file.exists(f8_highcov$source_fastq_R1))
all(file.exists(f8_highcov$source_fastq_R2))

# Arrange the columns and write to disk
f8_highcov %>%
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
    "02_input_sample_sheets/F8_highcov_input_sheet.tsv"
  )
