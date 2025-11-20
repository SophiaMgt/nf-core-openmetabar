process LOTUS3 {
    //tag "$model_pheno"
    tag 'lotus3'
    clusterOptions = { "--job-name ${task.tag}" }

    container "https://depot.galaxyproject.org/singularity/lotus3:3.03--hdfd78af_1"
    containerOptions = "--bind ${projectDir}:${projectDir}"

    input:
    path design
    val fastq 
    path db
    path tax

    output:
    path "*" , optional:true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Récupération des args depuis le config (via withName)
    def args = task.ext.args ?: ''
    def args_list = args.tokenize()

    """
    echo "!! Check Input LOTUS3 process !!"
    echo "fastq     : $fastq"
    echo "workdir     : ${projectDir}"
    echo "ARGS     : {args_list.join(' ')}"

    cp -r ${projectDir}/modules/local/lotus3/DB .
    cp -r ${projectDir}/sdm .
    
    mkdir -p fastq_folder
    echo "[INFO] Copying FASTQ files:"
    for f in ${fastq.join(' ')}; do
        echo "  - \$f"
        cp \$f fastq_folder/
    done

    echo "[INFO] Running LOTUS3..."
    # 1 - mapping file
    #lotus3 -create_map mymap.txt -i fastq_folder/
    bash ${projectDir}/scripts/build_mapping.sh $design $params.demux 

    # 2 - lotus3
    lotus3 \\
        -m mymap.txt \\
        -i fastq_folder/ \\
        -o result_lotus3 \\
        -s sdm/sdm_ONT_LSSU.txt \\
        -refDB $db -tax4refDB $tax \\
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
