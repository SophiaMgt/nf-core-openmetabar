#!/usr/bin/env bash
set -euo pipefail

design_file="$1"
demux="$2"
output="${3:-mymap.txt}"

# Dossier contenant les FASTQ copiés par Nextflow
fastq_dir="fastq_folder"

# Nettoyer les retours Windows
sed -i 's/\r$//' "$design_file"

# Header
echo -e "#SampleID\tForwardPrimer\tReversePrimer\tfastqFile" > "$output"
IFS=$'\t'

{
    read -r header_line
    while read -r Sample_ID fastq_path barcodeF barcodeR primerF primerR; do
        [[ -z "$Sample_ID" ]] && continue

        # Déterminer FASTQ
        if [[ "$demux" == "true" ]]; then
            fq="sample_${Sample_ID}_filtered.fastq"
        else
            fq="$(basename "$fastq_path")"
        fi

        # Vérifier si le FASTQ est présent dans fastq_folder
        if [[ ! -f "$fastq_dir/$fq" ]]; then
            echo "[WARN] FASTQ not found in $fastq_dir → skipping: $fq" >&2
            continue
        fi

        # Écrire la ligne si OK
        printf "%s\t%s\t%s\t%s\n" "$Sample_ID" "$primerF" "$primerR" "$fq"
    done
} < "$design_file" >> "$output"

echo "[INFO] Mapping file created: $output"