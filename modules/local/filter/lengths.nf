process LENGTHS_FILTER {

    container "oras://registry.forge.inrae.fr/sophia.marguerit/seqkit/seqkit:latest"

    input:
    tuple path(fastq_file)
    //path fastq_file       
    val expected_lengths  // liste des longueurs attendues

    output:
    tuple path("*_filtered.fastq"), emit: filtered_fastq

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

    // """
    // echo "[INFO] Filtering ${fastq_file} ..."
    // echo "[INFO] Accepted length ranges: ${ranges.collect{ it.min + '-' + it.max }.join(', ')}"

    // # Filtrage des séquences avec seqkit
    // seqkit seq ${seqkit_filters} -w 0 ${fastq_file} -o ${fastq_file.simpleName}_filtered.fastq

    // """

    if (fastq_file.size() == 2) {
            """
            echo "[INFO] Paired-end filtering ${fastq_file}"

            seqkit seq ${seqkit_filters} -w 0 ${fastq_file[0]} -o ${fastq_file[0].simpleName}_filtered.fastq
            seqkit seq ${seqkit_filters} -w 0 ${fastq_file[1]} -o ${fastq_file[1].simpleName}_filtered.fastq
            """
        }
        else {
            """
            echo "[INFO] Single-end filtering ${fastq_file}"

            seqkit seq ${seqkit_filters} -w 0 ${fastq_file[0]} -o ${fastq_file[0].simpleName}_filtered.fastq
            """
        }
}