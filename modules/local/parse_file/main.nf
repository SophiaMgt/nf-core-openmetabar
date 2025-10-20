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

    # Extraire les chemins FASTQ (colonne 2)
    awk 'NR>1 && !/^#/ {print \$2}' ${design_file} | sort | uniq > fastq_paths.txt
    n=\$(wc -l < fastq_paths.txt)

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