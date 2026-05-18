process QUALITY_FILTER {

    container "oras://registry.forge.inrae.fr/sophia.marguerit/seqkit/seqkit:latest"

    input:
    tuple path(fastq_file)
    val qual

    output:
    tuple path("*.qual.fastq"), emit: filtered_fastq

    script:
    if (fastq_file.size() == 2) {
            """
            echo "[INFO] Paired-end filtering ${fastq_file}"

            seqkit seq -Q ${qual} ${fastq_file[0]} -o ${fastq_file[0].simpleName}.qual.fastq
            seqkit seq -Q ${qual} ${fastq_file[1]} -o ${fastq_file[1].simpleName}.qual.fastq
            """
        }
        else {
            """
            echo "[INFO] Single-end filtering ${fastq_file}"

            seqkit seq -Q ${qual} ${fastq_file[0]} -o ${fastq_file[0].simpleName}.qual.fastq
            """
        }
}