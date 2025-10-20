// modules/local/minibar/main.nf
process MINIBAR {
    tag "minibar"

    container "oras://registry.forge.inrae.fr/sophia.marguerit/minibar/minibar:latest"

    input:
    path fastq           // fichier fastq réel (staged par Nextflow)
    path barcode         // fichier barcode (staged), si optional gérer côté appel

    output:
    path "output_minibar", emit: minibar_results
    //path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def args_list = args.tokenize()
    """
    set -euo pipefail
    echo "!! Check Input MINIBAR process !!"
    echo "FASTQ    : $fastq"
    echo "MANIFEST : $barcode"
    echo "ARGS     : ${args_list.join(' ')}"

    mkdir -p output_minibar
    cd output_minibar

    minibar \\
        ../${barcode} \\
        ../${fastq} \\
        ${args_list.join(' ')}

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
