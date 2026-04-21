process NEXTITS {
    tag 'NextITS'
    clusterOptions = { "--job-name ${task.tag}" }
    
    input:
    path designFile
    path fastq_folder
    path db_chimera

    output:
    path "*" , optional:true
    path "Step2_Results/05.LULU/OTUs_LULU.fa.gz" , optional:true, emit: otu_lulu
    path "versions.yml", emit: versions

    script:

    // Récupération des args depuis le config (via withName)
    def args = task.ext.args ?: ''
    def args_list = args.tokenize()

    def args2 = task.ext.args2 ?: ''
    def args_list2 = args2.tokenize()
    """
    echo "!! Check Input NextITS process !!"

    primer_forward=\$(awk -F '\\t' 'NR==2 {print \$5}' ${designFile})
    primer_reverse=\$(awk -F '\\t' 'NR==2 {print \$6}' ${designFile})

    echo "Primer forward: \$primer_forward"
    echo "Primer reverse: \$primer_reverse"

    # NextITS Step 1
    nextflow run vmikk/NextITS \
        -r main \
        -profile singularity \
        -with-singularity /home/smarguerit/work/METAB/pipeline/singularity/vmiks-nextits-nextits-1-2-0.img \
        --step Step1 \
        --demultiplexed true \
        --input ${fastq_folder} \
        --primer_forward "\$primer_forward" \
        --primer_reverse "\$primer_reverse" \
        --chimera_db /home/smarguerit/work/METAB/pipeline/mateo_data/UN95_chimera.udb \
        --outdir "Step1_result" \
        ${args_list.join(' ')}

    # NextITS Step 2
    nextflow run vmikk/NextITS \
        -r main \
        -profile singularity \
        -with-singularity /home/smarguerit/work/METAB/pipeline/singularity/vmiks-nextits-nextits-1-2-0.img \
        --step "Step2" \
        --data_path "." \
        --outdir "Step2_Results" \
        ${args_list.join(' ')}
 
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
