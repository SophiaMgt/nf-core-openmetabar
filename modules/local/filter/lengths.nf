process LENGTHS_FILTER {

    container "oras://registry.forge.inrae.fr/sophia.marguerit/seqkit/seqkit:latest"

    input:
    path fastq_file       // minibar output
    val expected_lengths  // liste des longueurs attendues

    output:
    path "${fastq_file.simpleName}_filtered.fastq", emit: filtered_fastq
    
    script:
    // Calcul des plages ±10% pour chaque longueur attendue
    def ranges = expected_lengths.collect { len ->
        def min = Math.round(len * 0.9)
        def max = Math.round(len * 1.1)
        return [min: min, max: max]
    }

    // Construction de la commande seqkit pour toutes les plages
    def seqkit_filters = ranges.collect { r ->
        "-m ${r.min} -M ${r.max}"
    }.join(" ")

    """
    echo "[INFO] Filtering ${fastq_file} ..."
    echo "[INFO] Accepted length ranges: ${ranges.collect{ it.min + '-' + it.max }.join(', ')}"

    # Filtrage des séquences avec seqkit
    seqkit seq ${seqkit_filters} -w 0 ${fastq_file} -o ${fastq_file.simpleName}_filtered.fastq

    """
}