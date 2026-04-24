process GENERATE_TAX4REFDB {
    tag "$index_name"

    input:
    tuple val(index_name), path(fasta)

    output:
    path "*.tax", emit: tax
    path "versions.yml", emit: versions

    script:
    """
    python ${projectDir}/scripts/generate_tax4refdb.py "${fasta}" "${params.db_type}" "${index_name}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """

    stub:
    """
    printf "stub_reference\\tUnknown;Unknown;Unknown;Unknown;Unknown;Unknown;Unknown\\n" > ${index_name}.tax

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: "stub"
    END_VERSIONS
    """
}