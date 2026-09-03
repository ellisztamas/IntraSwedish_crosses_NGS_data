#!/usr/bin/env bash
# =============================================================================
# md5_check.sh
#
# Compute MD5 checksums for all FASTQ files listed in the 'target_fastq_R1' and
# 'target_fastq_R2' columns of a tab-delimited sample sheet. All checksums are
# computed in parallel within a single SLURM job using GNU parallel or
# xargs -P (whichever is available), avoiding job array limits entirely.
# The output is a TSV with columns 'file_name' and 'file_md5'.
#
# USAGE
#   Call the script directly (do NOT use sbatch) — it self-submits to SLURM:
#
#       bash md5_check.sh /path/to/sample_sheet.tsv [/path/to/output_dir]
#
#   The output directory is optional. If omitted it defaults to
#   md5_results/ created next to the sample sheet.
#
#   The script detects whether it is running in submitter or worker context
#   via $SLURM_JOB_ID and behaves accordingly.
#
# REQUIREMENTS
#   - Tab-delimited sample sheet with a header row containing the columns
#     'target_fastq_R1' and 'target_fastq_R2'. Column 'target_fastq_R2' may be empty.
#   - md5sum available on compute nodes (standard on Linux clusters).
#   - GNU parallel or xargs available on compute nodes.
# =============================================================================

# ---- SLURM directives (applied when this script is submitted as a job) ------
#SBATCH --job-name=md5_check
#SBATCH --time=04:00:00
# Note: --cpus-per-task, --mem, --partition, --output, and --error are set at
#       submission time so they can be derived from the number of files.

set -euo pipefail

# =============================================================================
# INPUTS / OUTPUTS
# Edit the variables in this section to match your cluster and file layout.
# =============================================================================

# Input: path to the tab-delimited sample sheet (provided as $1 on the command line)
SAMPLE_SHEET="${1:?ERROR: No sample sheet provided.  Usage: bash $0 <sample_sheet.tsv> [output_dir]}"
SAMPLE_SHEET="$(realpath "$SAMPLE_SHEET")"       # Resolve to absolute path

# Output directory — defaults to md5_results/ next to the sample sheet if not provided
OUT_DIR="${2:-$(dirname "$SAMPLE_SHEET")/md5_results}"
OUT_DIR="$(realpath -m "$OUT_DIR")"              # Resolve to absolute path (dir need not exist yet)

# SLURM partition / queue — adjust to your cluster (e.g. "short", "compute", "cpu")
PARTITION="c"

# Maximum number of parallel md5sum processes to run simultaneously
MAX_JOBS=16

# =============================================================================
# DERIVED PATHS  (not intended to be edited)
# =============================================================================
SCRIPT="$(realpath "$0")"
LOG_DIR="${OUT_DIR}/logs"
FILE_LIST="${OUT_DIR}/file_list.txt"
FINAL_OUTPUT="${OUT_DIR}/md5_checksums.tsv"

# =============================================================================
# SUBMITTER MODE — script called directly by the user, outside of SLURM
# =============================================================================
if [[ -z "${SLURM_JOB_ID:-}" ]]; then

    echo "============================================="
    echo " md5_check.sh  —  Submitter mode"
    echo "============================================="
    echo " Sample sheet : $SAMPLE_SHEET"
    echo " Output dir   : $OUT_DIR"
    echo " File list    : $FILE_LIST"
    echo " Final output : $FINAL_OUTPUT"
    echo ""

    mkdir -p "$OUT_DIR" "$LOG_DIR" \
        || { echo "ERROR: Could not create output directory: $OUT_DIR" >&2; exit 1; }

    # -------------------------------------------------------------------------
    # Build a flat, one-file-per-line list from target_fastq_R1 and target_fastq_R2.
    # Column indices are detected dynamically from the header row so the script
    # works with any tab-delimited sample sheet that contains these columns.
    # Windows-style carriage returns (\r) are stripped throughout.
    # -------------------------------------------------------------------------
    awk -F'\t' '
        NR == 1 {
            for (i = 1; i <= NF; i++) {
                gsub(/\r/, "", $i)
                if ($i == "target_fastq_R1")                  col1 = i
                if ($i == "target_fastq_R2" || $i == "file_name_2") col2 = i
            }
            if (!col1) {
                print "ERROR: column \"target_fastq_R1\" not found in header" > "/dev/stderr"
                exit 1
            }
            if (!col2) {
                print "ERROR: neither \"target_fastq_R2\" nor \"file_name_2\" found in header" > "/dev/stderr"
                exit 1
            }
            next
        }
        {
            gsub(/\r/, "")
            if ($col1 != "") print $col1
            if ($col2 != "") print $col2
        }
    ' "$SAMPLE_SHEET" > "$FILE_LIST"

    [[ -f "$FILE_LIST" ]] \
        || { echo "ERROR: file_list.txt was not created — check column names in the sample sheet header." >&2; exit 1; }

    N=$(wc -l < "$FILE_LIST")
    [[ $N -eq 0 ]] && { echo "ERROR: No files found in sample sheet — check column names in the header." >&2; exit 1; }

    echo " First few entries in file list:"
    head -5 "$FILE_LIST"
    echo ""

    # Cap parallel jobs at the number of files (no point requesting more CPUs)
    CPUS=$(( MAX_JOBS < N ? MAX_JOBS : N ))

    echo " Files to checksum : $N"
    echo " Parallel jobs     : $CPUS"
    echo " Partition         : $PARTITION"
    echo ""

    # -------------------------------------------------------------------------
    # Submit a single job. Pass FILE_LIST and FINAL_OUTPUT to the worker via
    # environment variables.
    # -------------------------------------------------------------------------
    JOB_ID=$(sbatch \
        --partition="$PARTITION" \
        --cpus-per-task="$CPUS" \
        --mem="$(( CPUS * 512 ))M" \
        --output="${LOG_DIR}/md5_%j.out" \
        --error="${LOG_DIR}/md5_%j.err" \
        --export="ALL,FILE_LIST=${FILE_LIST},FINAL_OUTPUT=${FINAL_OUTPUT},MAX_JOBS=${CPUS}" \
        "$SCRIPT" "$SAMPLE_SHEET" "$OUT_DIR" \
        | awk '{print $NF}')

    echo " Job submitted : Job ID ${JOB_ID}"
    echo ""
    echo " Monitor progress with : squeue -j ${JOB_ID}"
    echo " Live log              : tail -f ${LOG_DIR}/md5_${JOB_ID}.out"
    echo " Logs directory        : $LOG_DIR"
    echo "============================================="
    exit 0
fi

# =============================================================================
# WORKER MODE — running inside the SLURM job on a compute node
# =============================================================================

echo "Worker started on $(hostname) at $(date)"
echo "Files to process: $(wc -l < "$FILE_LIST")"
echo "Parallel jobs:    $MAX_JOBS"
echo ""

# Helper: compute md5sum for one file and print a TSV row
checksum_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "WARNING: File not found, skipping: $file" >&2
        return 0
    fi
    local md5
    md5=$(md5sum "$file" | awk '{print $1}')
    printf '%s\t%s\n' "$file" "$md5"
}
export -f checksum_file

# Write header
printf 'file_name\tfile_md5\n' > "$FINAL_OUTPUT"

# Run checksums in parallel — prefer GNU parallel, fall back to xargs -P
if command -v parallel &>/dev/null; then
    echo "Using GNU parallel"
    parallel --jobs "$MAX_JOBS" --keep-order checksum_file :::: "$FILE_LIST" >> "$FINAL_OUTPUT"
else
    echo "GNU parallel not found — using xargs -P"
    xargs -a "$FILE_LIST" -P "$MAX_JOBS" -I{} bash -c 'checksum_file "$@"' _ {} >> "$FINAL_OUTPUT"
fi

N_OUT=$(( $(wc -l < "$FINAL_OUTPUT") - 1 ))
echo ""
echo "Done at $(date)"
echo "Files checksummed : $N_OUT"
echo "Output written to : $FINAL_OUTPUT"
