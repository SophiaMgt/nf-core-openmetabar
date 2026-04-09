// modules/local/minibar/main.nf
process MINIBAR {
    tag "minibar"

    container "oras://registry.forge.inrae.fr/sophia.marguerit/minibar/minibar:latest"

    input:
    path fastq           // fichier fastq réel (staged par Nextflow)
    path barcode         // fichier barcode

    output:
    path "output_minibar", emit: minibar_results
    path "fastq_trim", emit : fastq_trim
    path "demux_metrics.tsv", emit : demux_metrics
    path "demux_trim_metrics.tsv", emit : demux_trim_metrics
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
    
    ## sequences non affiliées
    rm sample_unk* sample_Multiple*

    # ==== Résumé demux ====
    echo -e "sample\\treads_demux" > ../demux_metrics.tsv
    for f in sample_*.fastq; do
        sample_name=\$(basename "\$f" .fastq | sed 's/^sample_//')
        nb=\$(awk 'END{print NR/4}' "\$f")
        echo -e "\${sample_name}\\t\${nb}" >> ../demux_metrics.tsv
    done

    ## Netoyage du nom
    for f in sample_*; do
        mv "\$f" "\$(echo "\$f" | sed 's/^sample_//')"
    done

    cd ..

    ## script filtre demux
    bash ${projectDir}/scripts/filter_by_expected_barcode.sh ${barcode}

    # ==== Résumé post-filtre TSV pour rapport ====
    echo -e "sample\\treads_after_barcode_filter" > demux_trim_metrics.tsv
    for f in fastq_trim/*.fastq; do
        sample_name=\$(basename "\$f" .fastq)
        nb=\$(awk 'END{print NR/4}' "\$f")
        echo -e "\${sample_name}\\t\${nb}" >> demux_trim_metrics.tsv
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minibar: \$(minibar --version 2>&1)
    END_VERSIONS
    """

    stub:
    """
    mkdir -p output_minibar
    mkdir -p fastq_trim

    echo -e "sample\\treads_demux" > demux_metrics.tsv
    echo -e "sample\\treads_after_barcode_filter" > demux_trim_metrics.tsv

    touch minibar_summary.csv
    touch minibar_summary_after_trim.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minibar: "stub"
    END_VERSIONS
    """
}
