#!/usr/bin/env bash
set -euo pipefail

design_file="$1"
filter="$2"

fastq_dir="fastq_folder"

## sup les retours chariot windows
sed -i 's/\r$//' "$design_file"

out="mymap.txt"

IFS=$'\t'
{
    # header designFile
    read -r header_line

    # Transformation en tableau
    read -ra header_cols <<< "$header_line"

    # Les 4 premières colonnes requises
    base_header=("#SampleID" "ForwardPrimer" "ReversePrimer" "fastqFile")

    # Colonnes supplémentaires (modalités)
    extra_header=("${header_cols[@]:6}")

    # Print dans le mappingFile
    printf "%s\t" "${base_header[@]}" > "$out"
    printf "%s\t" "${extra_header[@]}" >> "$out"
    sed -i 's/\t$//' "$out"
    echo >> "$out"

    # Lire les lignes
    while IFS=$'\t' read -r -a cols; do
        [[ -z "${cols[0]}" ]] && continue

        Sample_ID="${cols[0]}"
        fastq_path="${cols[1]}"
        primerF="${cols[4]}"
        primerR="${cols[5]}"

        # Colonnes supplémentaires
        extra_values=("${cols[@]:6}")

        if [[ "$filter" == "true" ]]; then
            fq="${Sample_ID}_filtered.fastq"
        else
            fq="$(basename "$fastq_path")"
        fi

        if [[ ! -f "$fastq_dir/$fq" ]]; then
            echo "[WARN] FASTQ not found in $fastq_dir → skipping: $fq" >&2
            continue
        fi

        printf "%s\t%s\t%s\t%s\t" \
            "$Sample_ID" \
            "$primerF" \
            "$primerR" \
            "$fq" >> "$out"

        printf "%s\t" "${extra_values[@]}" >> "$out"

        sed -i '$ s/\t$//' "$out"
        echo >> "$out"

    done
} < "$design_file"

echo "[INFO] Mapping file created: $out"