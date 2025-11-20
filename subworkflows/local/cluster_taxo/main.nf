// subworkflows/local/cluster_taxo/main.nf
include { LOTUS3 } from '../../../modules/local/lotus3/main'

workflow CLUSTER_TAXO {
    take:
    design
    fastq
    db
    tax

    
    main:
    
    LOTUS3(design,fastq,db,tax)
    
    //emit:

}