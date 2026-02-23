// modules/local/report/main.nf
process REPORT {
    tag "report"

    container "oras://registry.forge.inrae.fr/sophia.marguerit/report_py_2_word/report_py_2_word:latest"

    input:
    val demux

    output:
    path "report_idmabio.docx", emit: report_idmabio

    script:
    """
    set -euo pipefail
    echo "[INFO] Info  ${demux}"

    python ${projectDir}/scripts/generate_report.py

    # Versions (debug)
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        report: "1.1"
    END_VERSIONS
    """
}