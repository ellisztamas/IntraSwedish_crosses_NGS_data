#' Script to create a Reads submission sheet for the European Nucleotide
#' Archive
#'
#' Starting from a minimal sample sheet giving file details, and a text
#' file containing md5 hashes for those files, this script:
#'     - detects whether the dataset are likely to be single- or
#'       paired end, and the file type (bam or fastq)
#'     - merges the sample sheet with the corresponding checksums
#'     - writes a text file to disk in the correct format given pairing
#'       and data type that can be submitted to ENA.
#'
#'  Arguments:
#'  sample sheet:
#'    Tab-delimited text file with at least the following columns:
#'      'study': BioProject name at ENA.
#'      'sample_alias': Biological sample name.
#'      'forward_file_name': path to a bam or fastq file for the forward read.
#'      'reverse_file_name': Optional path to fastq file for the reverse read.
#'          If data are single-end this can be omitted or left blank.
#'  md5checksums:
#'    Tab-delimited text file with two columns:
#'      'file_name': paths to every file in the sample sheet.
#'          Paths need to match in both files.
#'      'file_md5': md5 hashes for each file.
#'  output file:
#'    Path to a file to save the output file.
#'
#'  Example usage:
#'     Rscript create_ENA_reads_sheet.R \
#'         sample_sheet.tsv \
#'         md5_hashes.txt \
#'         output_file.tsv
#'
#' Tom Ellis
#' 2026-09-10

args = commandArgs(trailingOnly=TRUE)

# Load the input arguments: path to a sample sheet, an output directory, and a
# file with MD5 hashes for each file names
sample_sheet_path <- args[1]
checksums_path <- args[2]
output_file <- args[3]

# sample_sheet_path <- "02_input_sample_sheets/F8_lowcov_input_sheet.tsv"
# checksums_path <-"04_create_checksums/F8_lowcov/md5_checksums.tsv"
# output_file <- "05_ENA_submission_sheets/F8_lowcov_reads.tsv"

# Install required packages if not already present
required_pkgs <- c("readr", "dplyr", 'tidyr')
to_install <- setdiff(required_pkgs, rownames(installed.packages()))
if (length(to_install) > 0) install.packages(to_install, repos = "https://cloud.r-project.org")
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
})



# Import and check the sample sheet ---------------------------------------

cat("Loading the sample sheet from", sample_sheet_path, "\n\n")
sample_sheet <- readr::read_tsv(sample_sheet_path, col_types = cols(.default = "c"))

# Confirm the necessary columns are all there.
# Check that all the expected columns are present in the sample sheet
# and that there are no missing entries
expected_col_names <- c('study','sample_alias', 'forward_file_name')
absent_cols <- ! expected_col_names %in% names(sample_sheet)
if(any(absent_cols)){
  stop(
    "One or more required columns was not found in the sample sheet: ",
    expected_col_names[absent_cols]
  )
}
if(any(is.na(sample_sheet[,expected_col_names]))){
  stop("One or more required columns contain missing data.")
}

# Confirm whether the data are paired or single end.
if(!"reverse_file_name" %in% names(sample_sheet)){
  cat("The sample sheet contains no column `reverse_file_name`.\n")
  cat("Data will be treated as single-end.\n\n")
  library_layout <- "SINGLE"
  # Blank column to ensure that subsequent checks and merges function
  sample_sheet$reverse_file_name <- NA
} else if(all(is.na(sample_sheet$reverse_file_name))){
  cat("The sample sheet contains only NA entries in `reverse_file_name`.\n")
  cat("The data will be treated as single-end.\n\n")
  library_layout <- "SINGLE"
} else if(any(is.na(sample_sheet$reverse_file_name))){
  stop("Column `reverse_file_name`contains a mixture of missing and non-missing entries. ",
       "Cannot process single- and paired-end data together.\n\n",
       "Split up the sample sheet by data type and repeat.")
} else {
  cat("The sample sheet contains columns `forward_file_name` and `reverse_file_name.\n")
  cat("The data will be treated as paired-end.\n\n")
  library_layout <- "PAIRED"
}

# Vector of file suffices for each file
# This requires that we enforced reverse_file_name so this can be
# a single vector operation, even if the column is NA.
file_extension_vec <- tools::file_ext(
  na.exclude(
    c(sample_sheet$forward_file_name, sample_sheet$reverse_file_name)
  )
)
# Confirm that the file_name are all only fastq or bam
file_names_match_format <- grepl("bam$|fastq$|gz$", file_extension_vec)
if( any(!file_names_match_format) ){
  stop("File extensions should be bam, fastq or .fastq.gz.")
}
# Confirm that the unique file extension is a correct type
# If data are fastq.gz, this will return 'gz'
# This is robust, because we already checked they are 'fastq.gz'
if( !unique(file_extension_vec) %in% c("bam", "fastq", 'gz')){
  stop("File extensions in column `file_name` should be bam, fastq or fastq.gz.")
}
# Check that only one file type is given
if(length(unique(file_extension_vec)) > 1){
  stop("Only one file type can be allowed in a single submission.")
}
# Determine the unique file extension so the output file can be formatted later
unique_file_extension <- unique(file_extension_vec)
# If data are gzipped fastq, these should be labelled as just fastq in the header of the datasheet
if(unique_file_extension == "gz"){
  unique_file_extension <- "fastq"
}

# Print a warning if any file_name appears more than once.
# Again, enforcing reverse_file_name means this can be a single vector operation
# It is difficult to manage this programmatically, so the user should check it manually.
file_name_vector <- c(sample_sheet$forward_file_name, sample_sheet$reverse_file_name)
file_name_counts <- table(file_name_vector)
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

if(all(file_name_vector %in% checksums$file_name)){
  cat("All file names in the sample sheet have checksums.\n")
} else{
  cat("One or more file names in the sample sheet do not have corresponding entries in the checksum file:\n")
  cat(file_name_vector[!file_name_vector %in% checksums$file_name], "\n\n")
  stop("Terminating due to missing checksums.")
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
    library_source = "GENOMIC",
    library_selection = "RANDOM",
    library_strategy = "WGS",
    library_layout = library_layout,
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

# If data are paired end, a simpler layout is needed.
# Note that this is independent of whether data are .bam or .fastq
if(library_layout == "SINGLE"){
  runs_sheet <- runs_sheet %>%
    rename(
      file_name = forward_file_name,
      file_md5  = forward_file_md5
    ) %>%
    select(-reverse_file_name, -reverse_file_md5)
}


# Write the output tibble--------------------------------------------------

# The output file needs to begin with a row giving the data type
header_line <- paste("FileType", unique_file_extension, "Read submission file type", sep = "\t")
cat(header_line, "\n", file = output_file, sep = "")

# Write the remaining rows , including the header.
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
readr::write_tsv(runs_sheet, output_file, append = TRUE, col_names = TRUE)
message("\nWrote output to: ", output_file)
