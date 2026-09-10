#' Script to create a sample sheet to submit raw reads to ENA
#'
#'
args = commandArgs(trailingOnly=TRUE)
# Load the input arguments: path to a sample sheet, an output directory, and a
# file with MD5 hashes for each file names
sample_sheet_path <- args[1]
checksums_path <- args[2]
output_directory <- args[3]

# sample_sheet_path <- "02_input_sample_sheets/F8_lowcov_input_sheet.tsv"
# output_directory <- "05_ENA_submission_sheets"
# checksums_path <-"04_create_checksums/F8_lowcov/md5_checksums.tsv"

# Install required packages if not already present
required_pkgs <- c("readr", "dplyr", 'tidyr')
to_install <- setdiff(required_pkgs, rownames(installed.packages()))
if (length(to_install) > 0) install.packages(to_install, repos = "https://cloud.r-project.org")
library(readr)
library(dplyr)
library(tidyr)



# Import and check the sample sheet ---------------------------------------

cat("Loading the sample sheet from", sample_sheet_path, "\n")
sample_sheet <- readr::read_tsv(sample_sheet_path, col_types = cols(.default = "c"))

# Confirm the necessary columns are all there.
# Check that all the expected columns are present in the sample sheet
expected_col_names <- c('sample_alias', 'target_fastq_R1', 'target_fastq_R2')
absent_cols <- ! expected_col_names %in% names(sample_sheet)
if(any(absent_cols)){
  stop(
    "One or more required columns was not found in the sample sheet: ",
    expected_col_names[absent_cols]
  )
}

# Rename columns to match ENA Reads submission requirements
sample_sheet <-sample_sheet %>%
  rename(
    forward_file_name = target_fastq_R1,
    reverse_file_name = target_fastq_R2
  )

# Print a warning if any file_name appears more than once.
# It is difficult to manage this programmatically, so the user should check it manually.
file_name_counts <- table(
  c(sample_sheet$forward_file_name, sample_sheet$reverse_file_name)
)
duplicated_file_names <- names(which(file_name_counts > 1))
if(any(file_name_counts > 1)){
  warning("One or more entries in file_name are duplicated.\n",
          "Check the output table and remove duplicate rows.")
  for(dup in duplicated_file_names){
    cat("Duplicate file_name:", dup,"\n")
  }
}



# Get the checksums -------------------------------------------------------

cat("Importing the table of checksums and merging with the sample sheet.\n")
checksums <- read_tsv(checksums_path, show_col_types = FALSE)


if(all(names(checksums) != c("file_name", "file_md5"))){
  stop("checksums file should have columns 'file_name' and 'file_md5'.")
}

if(all(sample_sheet$file_name %in% checksums$file_name)){
  cat("All file names in the sample sheet have checksums.\n")
} else{
  warning("One or more file names in the sample sheet do not have corresponding entries in the checksum file:\n")
  cat(sample_sheet$file_name[!sample_sheet$file_name %in% checksums$file_name], "\n\n")
}

# Merge with checksums, rename columns to match ENA specifications
sample_sheet <- sample_sheet %>%
  left_join(checksums, join_by(forward_file_name == file_name)) %>%
  rename(forward_file_md5 = file_md5) %>%
  left_join(checksums, join_by(reverse_file_name == file_name)) %>%
  rename(reverse_file_md5 = file_md5)


# Create the output tibble ------------------------------------------------

# Create the columns for a reads sample sheet, excluding the checksums
runs_sheet <- sample_sheet %>%
  # Fill in columns with some default values
  mutate(
    study = "PRJEB123735",
    instrument_model = "Illumina NovaSeq X",
    library_source = "GENOMIC",
    library_selection = "RANDOM",
    library_strategy = "WGS",
    library_layout = "PAIRED",
    forward_file_name = basename(forward_file_name),
    reverse_file_name = basename(reverse_file_name)
  ) %>%
  # Get the columns necessary, excluding checksums
  select(
    sample = sample_alias,
    study,
    instrument_model,
    library_name,
    library_source,
    library_selection,
    library_strategy,
    library_layout,
    forward_file_name,
    forward_file_md5,
    reverse_file_name,
    reverse_file_md5
  )



# Write the output tibble--------------------------------------------------

# Enforce trailing slash on output_directory
output_directory <- sub("/?$", "/", output_directory)
# Define output file in the output directory
output_file <- paste0(output_directory, basename(sample_sheet_path) )
# Change the file name, so there is no risk of overwriting the original file.
output_file <- gsub(".tsv$", "_forENA.tsv", output_file)

# If data are gzipped fastq, these should be labelled as just fastq in the header of the datasheet
if(file_extension == "gz"){
  file_extension <- "fastq"
}

# The output file needs to begin with a row giving the data type
header_line <- paste("FileType", 'fastq', "Read submission file type", sep = "\t")
cat(header_line, "\n", file = output_file, sep = "")

# Write the remaining rows , including the header.
readr::write_tsv(runs_sheet, output_file, append = TRUE, col_names = TRUE)
message("Wrote output to: ", output_file)
