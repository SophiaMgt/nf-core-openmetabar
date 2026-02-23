process LOTUS3 {
    //tag "$model_pheno"
    tag 'lotus3'
    clusterOptions = { "--job-name ${task.tag}" }

    //container "https://depot.galaxyproject.org/singularity/lotus3:3.03--hdfd78af_1"
    containerOptions = "--bind ${projectDir}:${projectDir}"

    input:
    //path design
    path mapping_file
    path fastq_folder
    path db
    path tax

    output:
    path "*" , optional:true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Définir un output basé sur le nom du fichier mapping
    def map_basename = mapping_file.baseName
    def outdir = "result_lotus3_${map_basename}"

    // Récupération des args depuis le config (via withName)
    def args = task.ext.args ?: ''
    def args_list = args.tokenize()

    """
    echo "!! Check Input LOTUS3 process !!"
    echo "fastq     : $fastq_folder"
    echo "maping_file  : $mapping_file"
    echo "workdir     : ${projectDir}"
    echo "ARGS     : {args_list.join(' ')}"

    cp -r ${projectDir}/modules/local/lotus3/DB .
    cp -r ${projectDir}/sdm .

    # 2 - lotus3
    lotus3 \\
        -m $mapping_file \\
        -i fastq_folder/ \\
        -o $outdir \\
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
