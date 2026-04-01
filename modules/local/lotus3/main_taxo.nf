process LOTUS3_TAXO {

    //container "https://depot.galaxyproject.org/singularity/lotus3:3.03--hdfd78af_1"
    containerOptions = "--bind ${projectDir}:${projectDir}"

    input:
    //path design
    path otu_table
    path db
    path tax

    output:
    path "*" , optional:true
    path "versions.yml", emit: versions

    script:
    """
    lotus3 \\
        -TaxOnly \\
        -o lotus_taxo \\
        -refDB ${db} -tax4refDB ${tax} \\
        -useBestBlastHitOnly 1 \
        -taxAligner 1

    ## Filtre la table d'occurance avec la table de taxo

 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lotus3: \$(v --version 2>&1) 
    END_VERSIONS
    """

    stub:
    """
    touch lotus3_output.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lotus3: "stub"
    END_VERSIONS
    """
}
