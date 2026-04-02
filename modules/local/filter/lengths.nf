process LENGTHS_FILTER {

    container "oras://registry.forge.inrae.fr/sophia.marguerit/seqkit/seqkit:latest"

    input:
    tuple path(fastq_file)
    //path fastq_file       
    val expected_lengths  // liste des longueurs attendues

    output:
    tuple path("*_filtered.fastq"), emit: filtered_fastq
    path "length_filter_metrics.tsv", emit: metrics
    
    script:
    // Calcul des plages ±10% pour chaque longueur attendue
    def ranges = expected_lengths.collect { len ->
        def min = Math.max(0, len - 100)
        def max = len + 100
        return [min: min, max: max]
    }

    // Construction de la commande seqkit pour toutes les plages
    def seqkit_filters = ranges.collect { r ->
        "-m ${r.min} -M ${r.max}"
    }.join(" ")

    if (fastq_file.size() == 2) {
        """
        echo "[INFO] Paired-end filtering ${fastq_file}"
        echo -e "sample\\treads_before_filter\\treads_after_filter" > length_filter_metrics.tsv

        for fq in ${fastq_file[0]} ${fastq_file[1]}; do
            sample_name=\$(basename "\$fq" .fastq)

            n_before=\$(awk 'END{print NR/4}' "\$fq")

            seqkit seq ${seqkit_filters} -w 0 "\$fq" -o \${sample_name}_filtered.fastq

            n_after=\$(awk 'END{print NR/4}' "\${sample_name}_filtered.fastq")

            echo -e "\${sample_name}\\t\${n_before}\\t\${n_after}" >> length_filter_metrics.tsv
        done
        """
    }

    else {
        """
        echo "[INFO] Single-end filtering ${fastq_file}"
        echo -e "sample\\treads_before_filter\\treads_after_filter" > length_filter_metrics.tsv

        fq=${fastq_file[0]}
        sample_name=\$(basename "\$fq" .fastq)

        n_before=\$(awk 'END{print NR/4}' "\$fq")

        seqkit seq ${seqkit_filters} -w 0 "\$fq" -o \${sample_name}_filtered.fastq

        n_after=\$(awk 'END{print NR/4}' "\${sample_name}_filtered.fastq")

        echo -e "\${sample_name}\\t\${n_before}\\t\${n_after}" >> length_filter_metrics.tsv
        """
    }
}