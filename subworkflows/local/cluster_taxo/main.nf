// subworkflows/local/cluster_taxo/main.nf
include { LOTUS3 } from '../../../modules/local/lotus3/main'

workflow CLUSTER_TAXO {
    take:
    fastq
    db
    tax

    
    main:
    LOTUS3(fastq,db,tax)
    
    //emit:

}