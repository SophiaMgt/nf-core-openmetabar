// subworkflows/local/cluster_taxo/main.nf
include { LOTUS3 as LOTUS_part1 } from '../../../modules/local/lotus3/main'
//include { LOTUS3 as LOTUS_part2 } from '../../../modules/local/lotus3/main'

workflow CLUSTER_TAXO {
    take:
    map1
    fastq
    db
    tax

    main:
    // Utiliser un process temporaire pour "print" le contenu
    map1.view { "Inside CLUSTER_TAXO, map1 → $it" }
    //map2.view { "Inside CLUSTER_TAXO, map1 → $it" }

    db.view { "Inside CLUSTER_TAXO, db → $it" }
    tax.view { "Inside CLUSTER_TAXO, tax → $it" }
    //val_map1 = map1.first()
    // val_map1.subscribe { v ->
    //     println "Première valeur de map1 : $v"}
    //val_map2 = map2.first()

    //val_map2.combine(fastq)

    // Lancer LOTUS3 sur chaque fichier
    LOTUS_part1(map1, fastq, db, tax)
    
    //LOTUS_part2(map2, fastq, db, tax)

    // mapping_files.each { mapping_file ->
    //     LOTUS3(
    //         mapping_file,
    //         fastq,
    //         db,
    //         tax
    //     )
    // }

}