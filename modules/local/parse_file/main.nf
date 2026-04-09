// modules/local/parse_file/main.nf
process PARSE_FILE {
    tag "parse_file"

    input:
    path design_file

    output:
    path "fastq_paths.txt", emit: fastq_paths        // 1 FASTQ par ligne
    path "barcode.txt", optional: true, emit: barcode_file
    path "design_file_cleaned.txt" , emit: design_file
    path "input_summary.tsv", emit: summary_metrics // metrics

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

    # Nombre d'échantillons
    n_samples=\$(awk 'NR>1 && !/^#/ {print \$1}' "\$design_file" | sort -u | wc -l | tr -d ' ')

    # Extraire les chemins FASTQ (col 2)
    awk 'NR>1 && !/^#/ {print \$2}' "\$design_file" | sort -u > fastq_paths.txt
    n_fastq=\$(wc -l < fastq_paths.txt)

    echo "[INFO] Found \$n_samples sample(s)."
    echo "[INFO] Extracted \$n_fastq FASTQ path(s)."

    # Compter le nombre total de reads dans les FASTQ
    total_reads=0
    while IFS= read -r fq; do
        if [ ! -f "\$fq" ]; then
            echo "[ERROR] FASTQ file not found: \$fq"
            exit 1
        fi

        if [[ "\$fq" == *.gz ]]; then
            n_reads=\$(zcat "\$fq" | awk 'END{print NR/4}')
        else
            n_reads=\$(awk 'END{print NR/4}' "\$fq")
        fi

        echo "[INFO] \$fq : \$n_reads reads"
        total_reads=\$((total_reads + n_reads))
    done < fastq_paths.txt

    echo "[INFO] Total input reads: \$total_reads"

    # Écrire le résumé global
    {
        echo -e "metric\\tvalue"
        echo -e "n_samples\\t\${n_samples}"
        echo -e "n_fastq\\t\${n_fastq}"
        echo -e "n_reads_input\\t\${total_reads}"
    } > input_summary.tsv

    # Créer barcode.txt pour demultiplexage
    if [ "${params.demux}" = "true" ]; then
        echo "[INFO] Demultiplexing requested → generating barcode.txt"

        # Sample_ID | barcodeF | primerF | barcodeR | primerR
        awk 'NR>1 {print \$1"\\t"\$3"\\t"\$5"\\t"\$4"\\t"\$6}' "\$design_file" > barcode.txt
    else
        echo "[INFO] Demultiplexing disabled → no barcode.txt generated"
        touch barcode.txt
    fi

    # Versions (debug)
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parse_file: "1.1"
    END_VERSIONS
    """
}