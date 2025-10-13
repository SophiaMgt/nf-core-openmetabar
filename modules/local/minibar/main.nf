process MINIBAR {
    tag "minibar"
    clusterOptions = { "--job-name ${task.tag}" }

    container "oras://registry.forge.inrae.fr/sophia.marguerit/minibar/minibar:latest"

    input:
    path fastq
    path barcode

    output:
    path "output_minibar" , emit: minibar_results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Récupération des args depuis le config (via withName)
    def args = task.ext.args ?: ''
    def args_list = args.tokenize()

    """
    echo "!! Check Input MINIBAR process !!"
    echo "FASTQ    : $fastq"
    echo "MANIFEST : $barcode"
    echo "ARGS     : ${args_list.join(' ')}"

    mkdir output_minibar
    cd output_minibar

    ## lien symbolique local
    ##ln -s fastq_path ./input.fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minibar: \$(minibar --version 2>&1)
    END_VERSIONS
    """

    stub:
    """
    mkdir outputminibar
    cd output minibar

    touch output_minibar.txt
    cd ..
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minibar: "stub"
    END_VERSIONS
    """
}
