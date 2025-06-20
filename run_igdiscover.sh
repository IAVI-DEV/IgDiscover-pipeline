#!/bin/bash

# General-purpose IgDiscover runner
# Usage:
# ./run_igdiscover.sh <ID> <BASE_PATH> <DB_PATH> <FASTQ_DIR> [R1.fastq.gz] [CONFIG_PATH]

set -euo pipefail

# --- Input Validation ---
if [[ $# -lt 4 ]]; then
    echo "Usage: $0 <ID> <BASE_PATH> <DB_PATH> <FASTQ_DIR> [R1.fastq.gz] [CONFIG_PATH]"
    echo
    echo "  <ID>           : Required sample ID (used to name the project)"
    echo "  <BASE_PATH>    : Required base path for project output (e.g. /data/igdiscover)"
    echo "  <DB_PATH>      : Required path to IgDiscover V gene database (e.g. /data/db/IGH)"
    echo "  <FASTQ_DIR>    : Required directory where R1 FASTQ files are stored"
    echo "  [R1.fastq.gz]  : Optional specific path to the R1 FASTQ file"
    echo "  [CONFIG_PATH]  : Optional custom igdiscover.yaml file path"
    exit 1
fi

# --- Positional Arguments ---
ID="$1"
BASE="$2"
DB="$3"
FASTQ_DIR="$4"
READ1_INPUT="${5:-}"
CUSTOM_CONFIG="${6:-$(dirname "$0")/igdiscover.yaml}"

# --- Derived Paths ---
PROJECT="$BASE/${ID}_igdiscover_project"
CONFIG_FILE="$PROJECT/igdiscover.yaml"

# --- Detect READ1 if not provided ---
if [ -n "$READ1_INPUT" ]; then
    READ1="$READ1_INPUT"
else
    READ1=$(find "$FASTQ_DIR" -type f -name "*${ID}*R1*.fastq.gz" | head -n 1)
fi

if [ ! -f "$READ1" ]; then
    echo "Error: R1 FASTQ file not found for sample ID '$ID'. Searched in $FASTQ_DIR."
    exit 1
fi

echo "Sample ID     : $ID"
echo "Project path  : $PROJECT"
echo "READ1 file    : $READ1"
echo "Database path : $DB"

# --- Create project ---
igdiscover init --reads1 "$READ1" --db "$DB" "$PROJECT"

# --- Replace config if provided ---
if [ ! -f "$CUSTOM_CONFIG" ]; then
    echo "Error: Custom config file not found at $CUSTOM_CONFIG"
    exit 1
fi

cp "$CUSTOM_CONFIG" "$CONFIG_FILE"
echo "Custom config copied to $CONFIG_FILE"

# --- Run IgDiscover ---
echo "Running IgDiscover..."
cd "$PROJECT"
igdiscover run 2>&1 | tee igdiscover_run.log
echo "IgDiscover pipeline completed."
