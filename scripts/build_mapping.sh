#!/usr/bin/env bash
set -euo pipefail

design_file="$1"
filter="$2"
demux="$3"
fastq_dir="fastq_folder"

## sup les retours chariot windows
sed -i 's/\r$//' "$design_file"

out="mymap.txt"

IFS=$'\t'

{   # --- HEADER ---
    read -r header_line
    read -ra header_cols <<< "$header_line"

    base_header=("#SampleID" "ForwardPrimer" "ReversePrimer" "fastqFile")
    extra_header=("${header_cols[@]:6}")

    printf "%s\t" "${base_header[@]}" > "$out"
    printf "%s\t" "${extra_header[@]}" >> "$out"
    sed -i 's/\t$//' "$out"
    echo >> "$out"
} < "$design_file"

while IFS=$'\t' read -r -a cols; do
    [[ -z "${cols[0]}" ]] && continue

    Sample_ID="${cols[0]}"
    fastq_path="${cols[1]}"
    primerF="${cols[4]}"
    primerR="${cols[5]}"
    extra_values=("${cols[@]:6}")

    fq_list=()
    if [[ "$demux" == "true" ]]; then
        # Chaque SampleID a déjà son propre FASTQ
        if [[ "$filter" == "true" ]]; then
            fq_candidate="${Sample_ID}_filtered.fastq"
        else
            fq_candidate="${Sample_ID}.fastq"
        fi

        if [[ -f "$fastq_dir/$fq_candidate" ]]; then
            fq_list+=("$fq_candidate")
        else
            echo "[WARN] FASTQ not found for SampleID $Sample_ID → skipping: $fq_candidate" >&2
            continue
        fi

    else
        # Cas non démultiplexé → juste R1 ou R1,R2 séparés par virgule
        IFS=',' read -ra parts <<< "$fastq_path"

        for part in "${parts[@]}"; do
            base="$(basename "$part")"

            if [[ "$filter" == "true" ]]; then
                base="${base%.fastq*}_filtered.fastq"
            fi

            if [[ -f "$fastq_dir/$base" ]]; then
                fq_list+=("$base")
            else
                echo "[WARN] FASTQ not found in $fastq_dir → skipping: $base" >&2
            fi
        done

        [[ ${#fq_list[@]} -eq 0 ]] && continue
    fi
    
    # Rejoindre les fichiers avec virgule pour la colonne fastqFile
    fq_str=$(IFS=','; echo "${fq_list[*]}")
    
    # Écrire dans le mapping file

    # Écrire dans le mapping file
    printf "%s\t%s\t%s\t%s\t" \
        "$Sample_ID" \
        "$primerF" \
        "$primerR" \
        "$fq_str" >> "$out"

    printf "%s\t" "${extra_values[@]}" >> "$out"
    sed -i '$ s/\t$//' "$out"
    echo >> "$out"

done < <(tail -n +2 "$design_file")

echo "[INFO] Mapping file created: $out"