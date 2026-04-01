process QUAL_FILTER {

    container "oras://registry.forge.inrae.fr/sophia.marguerit/seqkit/seqkit:latest"

    input:
    tuple path(fastq_file)
    val qual

    output:
    tuple path("*_qualFfiltered.fastq"), emit: filtered_fastq

    script:
    if (fastq_file.size() == 2) {
            """
            echo "[INFO] Paired-end filtering ${fastq_file}"

            seqkit seq -Q ${qual} ${fastq_file[0]} ${fastq_file[0].simpleName}_qualFiltered.fastq
            seqkit seq -Q ${qual} ${fastq_file[1]} ${fastq_file[1].simpleName}_qualFfiltered.fastq
            """
        }
        else {
            """
            echo "[INFO] Single-end filtering ${fastq_file}"

            seqkit seq -Q ${qual} ${fastq_file[0]} ${fastq_file[0].simpleName}_qualFfiltered.fastq
            """
        }
}