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

    path "lotus3_sample_summary.tsv", emit: sample_metrics
    path "lotus3_global_summary.tsv", emit: global_metrics
    
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
    # db pour l'outil lotus3 
    cp ${projectDir}/modules/local/lotus3/DB/phiX.fasta DB/.
    cp ${projectDir}/modules/local/lotus3/DB/rdp_gold.fa DB/.

    lotus3 \\
        -m ${mapping_file} \\
        -i ${fastq_folder} \\
        -s ${sdm_file} \\
        -o ${outdir} \\
        -refDB ${db} -tax4refDB ${tax} \\
        ${args_list.join(' ')}


    # ===== METRICS LOTUS3 =====

    # 1. nombre total de ZOTU (lignes sans header)
    nb_zotu_total=\$(awk 'NR>1{count++} END{print count}' ${outdir}/OTU.txt)

    # 2. nombre de ZOTU > 5 reads (somme des colonnes)
    nb_zotu_gt5=\$(awk '
    NR>1 {
        sum=0
        for(i=2;i<=NF;i++) sum+=\$i
        if(sum > 5) count++
    }
    END{print count}
    ' ${outdir}/OTU.txt)

    # 3. écrire global summary
    {
        echo -e "metric\tvalue"
        echo -e "nb_zotu_total\t\${nb_zotu_total}"
        echo -e "nb_zotu_gt5\t\${nb_zotu_gt5}"
    } > lotus3_global_summary.tsv

    # 4. trouver ZOTU majoritaire par sample
    echo -e "sample\tzotu_major\ttaxonomy\tabundance" > lotus3_sample_summary.tsv

    # récupérer header samples
    header=\$(head -1 ${outdir}/OTU.txt)

    # pour chaque colonne (sample)
    awk -v otu_file="${outdir}/OTU.txt" -v tax_file="${outdir}/hiera_BLAST.txt" '
    BEGIN {
        FS="\t"
    }

    NR==1 {
        for(i=2;i<=NF;i++) samples[i]=\$i
        next
    }

    {
        otu=\$1
        for(i=2;i<=NF;i++) {
            if(\$i > max[i]) {
                max[i]=\$i
                best_otu[i]=otu
            }
        }
    }

    END {
        for(i in samples) {
            print samples[i] "\t" best_otu[i] "\tNA\t" max[i]
        }
    }
    ' ${outdir}/OTU.txt >> lotus3_sample_summary.tsv    

 
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
