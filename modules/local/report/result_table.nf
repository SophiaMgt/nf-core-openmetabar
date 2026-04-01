// modules/local/report/main.nf
process RESULT_TABLE {
    tag "report"

    //container "oras://registry.forge.inrae.fr/sophia.marguerit/report_py_2_word/report_py_2_word:latest"

    input:
    path otu_table
    path otu_seq
    path otu_tax
    path blast

    output:
    path "*.csv", emit: table_final

    script:
    """
    set -euo pipefail
    
    echo "PROJECT DIR: ${projectDir}"
    ls ${projectDir}/scripts

    python ${projectDir}/scripts/table_final.py ${otu_table} ${otu_seq} ${otu_tax} ${blast }

    # Versions (debug)
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        report: "1.1"
    END_VERSIONS
    """
}