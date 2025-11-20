#!/usr/bin/env bash
set -euo pipefail

design_file="$1"
demux="$2"             # true / false
output="${3:-mymap.txt}"

if [[ ! -f "$design_file" ]]; then
    echo "[ERROR] Design file not found: $design_file" >&2
    exit 1
fi

# Detect delimiter automatically
delimiter=$(head -n1 "$design_file" | grep -q "," && echo "," || echo -e "\t")
echo "[INFO] Using delimiter: '$delimiter'"

# Read header
header=$(head -n1 "$design_file")
IFS="$delimiter" read -r -a cols <<< "$header"

# Write mapping header
echo -e "#SampleID\tForwardPrimer\tReversePrimer\tfastqFile" > "$output"

# Metadata columns (after column 6)
for ((i=6; i<${#cols[@]}; i++)); do
    echo -ne "\t${cols[$i]}" >> "$output"
done
echo "" >> "$output"

# Process each line
tail -n +2 "$design_file" | while IFS="$delimiter" read -r SampleID path barcodeF barcodeR primerF primerR rest; do

    # --------------- CASE 1 : demultiplexed -----------------
    if [[ "$demux" == "true" ]]; then
        fq="sample_${SampleID}_filtered.fastq"
    else
        # --------------- CASE 2 : NOT demultiplexed ----------
        fq="$path"
    fi

    echo -ne "${SampleID}\t${primerF}\t${primerR}\t${fq}" >> "$output"

    # Add metadata columns
    if [[ ! -z "${rest:-}" ]]; then
        echo -ne "\t${rest}"
    fi

    echo "" >> "$output"
done

echo "[INFO] Mapping file created: $output"