// modules/local/parse_file/main.nf
process PARSE_FILE {
    tag "parse_file"

    input:
    path design_file

    output:
    path "fastq_paths.txt", emit: fastq_paths        // 1 FASTQ par ligne
    path "barcode.txt", optional: true, emit: barcode_file
    path "design_file_cleaned.txt" , emit: design_file

    script:
    """
    set -euo pipefail
    echo "[INFO] Parsing design file: ${design_file}"

    # Vérification des colonnes obligatoires
    header=\$(head -1 ${design_file})
    required_cols=("Sample_ID" "fastq_path" "barcodeF" "barcodeR" "primerF" "primerR")
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
    awk -v OFS="\t" 'NR==1{print;next}{gsub(/-/, "_", \$1); print}' "${design_file}" > "\$tmp_clean"
    design_file="\$tmp_clean"

    # Extraire les chemins FASTQ (col 2)
    awk 'NR>1 && !/^#/ {print \$2}' "\$design_file" | sort | uniq > fastq_paths.txt
    n=\$(wc -l < fastq_paths.txt)
    echo "[INFO] Extracted \$n FASTQ path(s)."

    # Créer barcode.txt seulement si demultiplexage demandé
    if [ "${params.demux}" = "true" ]; then
        echo "[INFO] Demultiplexing requested → generating barcode.txt"

        # Sample_ID | barcodeF | primerF | barcodeR | primerR
        awk 'NR>1 {print \$1"\\t"\$3"\\t"\$5"\\t"\$4"\\t"\$6}' "\$design_file" > barcode.txt
    else
        echo "[INFO] Demultiplexing disabled → no barcode.txt generated"
    fi

    # Versions (debug)
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parse_file: "1.1"
    END_VERSIONS
    """
}