process BUILD_MAPPING_FILE {

    input:
    val fastq
    path design

    output:
    path "mymap.txt", emit: mapping_file
    //path "mymap_part2.txt", emit: mapping_file2
    path "fastq_folder/", emit: fastq_folder
    path "fastq_summary.txt", emit: fastq_summary
    path "versions.yml", emit: versions

    script:
    """
    echo "[INFO] Check Input build mapping_file process !!"
    echo "workdir     : ${projectDir}"

    mkdir -p fastq_folder

    echo "[INFO] Filtering FASTQ files (excluding empty ones)..."
    > fastq_non_empty.list

    for f in ${fastq.join(' ')}; do
        if [[ -s "\$f" ]]; then
            echo "  - KEEP  : \$f"
            cp "\$f" fastq_folder/
            echo "\$f" >> fastq_non_empty.list
        else
            echo "  - SKIP (EMPTY): \$f"
        fi
    done

    echo "[INFO] Total number of sequences (non-empty FASTQ only):"
    grep -h "^@" fastq_folder/*.fastq 2>/dev/null | wc -l || true

    echo "[INFO] Building mapping_file for Lotus3..."
    # mapping file split (only non-empty FASTQ are present)
    bash ${projectDir}/scripts/build_mapping.sh ${design} $params.filter $params.demux

    echo "[INFO] Creating FASTQ summary..."
    echo -e "File\tNumSequences\tStatus" > fastq_summary.txt

    for f in ${fastq.join(' ')}; do
        base=\$(basename "\$f")
        if [[ ! -s "\$f" ]]; then
            echo -e "\$base\t0\tEXCLUDED_EMPTY" >> fastq_summary.txt
        else
            count=\$(grep -c "^@" "\$f" || true)
            echo -e "\$base\t\$count\tUSED" >> fastq_summary.txt
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mapping_file building (split 2): \$(v --version 2>&1)
    END_VERSIONS
    """

    stub:
    """
    touch mymap.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
         mapping_file building (split 2): "stub"
    END_VERSIONS
    """
}