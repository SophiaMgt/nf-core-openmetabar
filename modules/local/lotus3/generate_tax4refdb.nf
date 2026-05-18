process GENERATE_TAX4REFDB {
    tag "$fasta"

    input:
    path fasta 

    output:
    path "*.tax", emit: tax
    path "*.cleaned.fasta", emit: cleaned_fasta
    path "versions.yml", emit: versions

    script:
    """
    python ${projectDir}/scripts/generate_tax4refdb.py "${fasta}" "${params.db_type}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //')
    END_VERSIONS
    """

    stub:
    """
    printf "stub_reference\\tUnknown;Unknown;Unknown;Unknown;Unknown;Unknown;Unknown\\n" > ${fasta}.tax

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: "stub"
    END_VERSIONS
    """
}