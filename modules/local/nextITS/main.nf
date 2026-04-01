process NEXTITS {
    tag 'NextITS'
    clusterOptions = { "--job-name ${task.tag}" }
    
    containerOptions = "--bind ${projectDir}:${projectDir}"
    
    input:
    path fastq_folder
    path db_chimera

    output:
    path "*" , optional:true
    path "Step2_Results/05.LULU/OTUs_LULU.fa.gz" , optional:true, emit: otu_lulu
    path "versions.yml", emit: versions

    script:

    // Récupération des args depuis le config (via withName)
    //def args = task.ext.args ?: ''
    //def args_list = args.tokenize()
    """
    echo "!! Check Input NextITS process !!"

    # NextITS Step 1
    nextflow run vmikk/NextITS \
        -r main \
        -profile singularity \
        -with-singularity /home/smarguerit/work/METAB/pipeline/singularity/vmiks-nextits-nextits-1-2-0.img \
        --step Step1 \
        --demultiplexed true \
        --input fastq_folder/ \
        --primer_forward "ACCWGCGGARGGATCATTA" \
        --primer_reverse "TCCTGAGGGAAACTTCG" \
        --its_region "LSU" \
        --ITSx_tax "all" \
        --chimera_db /home/smarguerit/work/METAB/pipeline/mateo_data/UN95_chimera.udb \
        --outdir "Step1_result" 

    # NextITS Step 2
    nextflow run vmikk/NextITS \
        -r main \
        -profile singularity \
        -with-singularity /home/smarguerit/work/METAB/pipeline/singularity/vmiks-nextits-nextits-1-2-0.img \
        --step "Step2" \
        --data_path "." \
        --clustering_method "unoise" \
        --unoise true \
        --outdir "Step2_Results" \
        --hp true
 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        NextITS: \$(v --version 2>&1) 
    END_VERSIONS
    """

    stub:
    """
    touch NextITS_output.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        NextITS: "stub"
    END_VERSIONS
    """
}
