process LOTUS3 {
    //tag "$model_pheno"

    input:
    //path design
    path map
    path db
    path tax

    output:
    path "*" , optional:true

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    echo "!! Check Input !!"

    cp -r ${projectDir}/modules/local/lotus3/DB .
    cp -r ${projectDir}/sdm .

    touch test_lotus.txt
    """

}
