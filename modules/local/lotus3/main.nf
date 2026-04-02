process LOTUS3 {
    //tag "$model_pheno"
    tag 'lotus3'

    input:
    path mapping_file
    path fastq_folder
    path db
    path tax

    def outdir = "result_lotus3"

    output:
    path "${outdir}/OTU.txt", emit: otu_table
    path "${outdir}/OTU.fna", emit: otu_seq
    path "${outdir}/hiera_BLAST.txt", emit: otu_taxo
    path "${outdir}/ExtraFiles/tax.0.blast", emit: blast_result
    path "*" , optional:true
    path "versions.yml", emit: versions

    script:
    // Récupération des args depuis le config (via withName)
    def args = task.ext.args ?: ''
    def args_list = args.tokenize()
    
    def sdm_file
    if (params.techno == "pacbio") {
        sdm_file = "${projectDir}/sdm/sdm_PacBio_LSSU.txt"
    }
    else if (params.techno == "ont") {
        sdm_file = "${projectDir}/sdm/sdm_ONT_LSSU.txt"
    }
    else if (params.techno == "illumina") {
        sdm_file = "${projectDir}/sdm/sdm_miSeq_ITS.txt"
    }

    """
    mkdir DB
    cp ${projectDir}/modules/local/lotus3/DB/phiX.fasta DB/.
    cp ${projectDir}/modules/local/lotus3/DB/rdp_gold.fa DB/.

    lotus3 \\
        -m ${mapping_file} \\
        -i ${fastq_folder} \\
        -s ${sdm_file} \\
        -o ${outdir} \\
        -refDB ${db} -tax4refDB ${tax} \\
        ${args_list.join(' ')}

 
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
