process PARSE_FILE {

    input:
    path design_file

    output:
    path "fastq_list.txt", emit: fastq_list
    path "needs_demux.txt", emit: needs_demux
    path "barcode.txt", optional: true, emit: barcode_file

    script:
    """
    echo "[INFO] Parsing design file: ${design_file}"

    # Take the fastq file(s) path
    awk 'NR>1 && !/^#/ {print \$2}' ${design_file} | sort | uniq > fastq_list.txt
    n=\$(wc -l < fastq_list.txt)

    if [ "\$n" -eq 1 ]; then
        echo "[INFO] All samples use the same FASTQ — demultiplexing required."
        echo "true" > needs_demux.txt

        # Build barecode_file
        # Exemple : on prend colonnes [sample_id, barcode]
        awk 'NR>1 {print \$1, \$3, \$5, \$4, \$6}' OFS="\\t" ${design_file} > barcode.txt

    else
        echo "[INFO] Multiple FASTQ detected — no demultiplexing."
        echo "false" > needs_demux.txt
    fi

    while read fq; do
        abs_path=\$(readlink -f "\$fq")
        ln -s "\$abs_path" .
    done < fastq_list.txt

        cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        build_barcode: "1.0"
    END_VERSIONS
    """

    stub:
    """
    touch fastq_list.txt
    touch needs_demux.txt
    touch barcode.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        build_barcode: "stub"
    END_VERSIONS
    """
}

