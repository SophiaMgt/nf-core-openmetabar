// modules/local/parse_file/main.nf
process PARSE_FILE {
    tag "parse_file"

    input:
    path design_file

    output:
    path "fastq_paths.txt", emit: fastq_paths        // contient 1 ligne par fastq
    path "needs_demux_flag.txt", emit: needs_demux   // "true" ou "false"
    path "barcode.txt", optional: true, emit: barcode_file


    script:
    """
    set -euo pipefail
    echo "[INFO] Parsing design file: ${design_file}"

    # Vérification des colonnes
    header=\$(head -1 ${design_file})
    required_cols=("SampleID" "fastq_path" "barcodeF" "barcodeR" "primerF" "primerR")
    missing_cols=()
    for col in "\${required_cols[@]}"; do
        if ! echo "\$header" | grep -qw "\$col"; then
            missing_cols+=("\$col")
        fi
    done

    if [ \${#missing_cols[@]} -gt 0 ]; then
        echo "[ERROR] Missing required column(s): \${missing_cols[@]}"
        exit 1
    fi

    # Nettoyage SampleID : '-' → '_'
    tmp_clean="design_file_cleaned.txt"
    echo "[INFO] Cleaning SampleID column (replacing '-' by '_')"

    awk -v OFS="\\t" 'NR==1 {print; next} {gsub(/-/, "_", \$1); print}' ${design_file} > \$tmp_clean

    # Warning si modification des SampleID
    if ! diff <(cut -f1 ${design_file} | tail -n +2) <(cut -f1 \$tmp_clean | tail -n +2) >/dev/null 2>&1; then
        echo "[INFO] SampleID(s) containing '-' were replaced by '_'"
    fi

    # Extraire les chemins FASTQ (colonne 2)
    awk 'NR>1 && !/^#/ {print \$2}' ${design_file} | sort | uniq > fastq_paths.txt
    n=\$(wc -l < fastq_paths.txt)
    echo "[INFO] Found \$n unique FASTQ path(s)."

    if [ "\$n" -eq 1 ]; then
        echo "[INFO] One FASTQ detected — demultiplexing required."
        echo "true" > needs_demux_flag.txt

        # Générer barcode.txt si les colonnes barcodeF/R existent (col 3/4 ici : adapte si besoin)
        header=\$(head -1 ${design_file})
        if echo "\$header" | grep -q -i "barcodeF"; then
            awk 'NR>1 {print \$1\"\\t\"\$3\"\\t\"\$5\"\\t\"\$4\"\\t\"\$6}' ${design_file} > barcode.txt || true
        fi
    else
        echo "[INFO] Multiple FASTQ detected — demultiplexing not required."
        echo "false" > needs_demux_flag.txt
    fi

    # versions file (utile pour debugging)
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parse_file: "1.0"
    END_VERSIONS
    """
}

