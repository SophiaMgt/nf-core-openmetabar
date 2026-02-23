#!/usr/bin/env bash
set -euo pipefail

design_file="$1"
demux="$2"
output_prefix="${3:-mymap}"   # on utilisera mymap_part1.txt et mymap_part2.txt

# Dossier contenant les FASTQ copiés par Nextflow
fastq_dir="fastq_folder"

# Nettoyer les retours Windows
sed -i 's/\r$//' "$design_file"

# compter le nombre de lignes (hors header)
num_samples=$(tail -n +2 "$design_file" | wc -l)
half=$(( (num_samples + 1) / 2 ))  # arrondi vers le haut

# fichiers de sortie
out1="${output_prefix}.txt"
#out2="${output_prefix}_part2.txt"

# header
echo -e "#SampleID\tForwardPrimer\tReversePrimer\tfastqFile" > "$out1"
#echo -e "#SampleID\tForwardPrimer\tReversePrimer\tfastqFile" > "$out2"

# lire et distribuer les lignes
IFS=$'\t'
count=0
{
    read -r header_line
    while read -r Sample_ID fastq_path barcodeF barcodeR primerF primerR; do
        [[ -z "$Sample_ID" ]] && continue

        # Déterminer FASTQ
        if [[ "$demux" == "true" ]]; then
            fq="${Sample_ID}_filtered.fastq"
        else
            fq="$(basename "$fastq_path")"
        fi

        # Vérifier si le FASTQ est présent
        if [[ ! -f "$fastq_dir/$fq" ]]; then
            echo "[WARN] FASTQ not found in $fastq_dir → skipping: $fq" >&2
            continue
        fi

        # choisir le fichier de sortie
        #if (( count < half )); then
        printf "%s\t%s\t%s\t%s\n" "$Sample_ID" "$primerF" "$primerR" "$fq" >> "$out1"
        #else
        #    printf "%s\t%s\t%s\t%s\n" "$Sample_ID" "$primerF" "$primerR" "$fq" >> "$out2"
        #fi

        count=$((count + 1))
    done
} < "$design_file"

echo "[INFO] Mapping files created: $out1"