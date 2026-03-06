// subworkflows/local/pacbio_16s/main.nf

//include { DEMULTIPLEX        } from '../../../modules/local/demultiplex'
//include { MINIBAR } from '../../../modules/local/minibar/main'

//include { PARSE_WORFLOW      } from '../subworkflows/local/parse_file'
include { PARSE_FILE } from '../../../modules/local/parse_file/main'

//include { MAPPING_FILE       } from '../subworkflows/local/mapping_file'
include { BUILD_MAPPING_FILE } from '../../../modules/local/lotus3/mapping_file'

//include { CLUSTER_TAXO       } from '../subworkflows/local/cluster_taxo'
include { LOTUS3  } from '../../../modules/local/lotus3/main'

include { FILTER             } from '../filter'
//include { REPORT             } from '../modules/local/report/main'

workflow PACBIO_LSU_ITS {

    take:
    ch_design
    db_ch
    tax_ch

    main:

    PARSE_FILE(ch_design)
    barcode_file_ch = PARSE_FILE.out.barcode_file // fichier vide
    design_file     = PARSE_FILE.out.design_file
    // Convertir fastq_paths.txt -> Channel<path> (un path par élément)
    fastq_list_ch = PARSE_FILE.out.fastq_paths
        .splitText()
        .map { line -> line.trim() }
        .filter { it }
        .map { line ->
            def parts = line.split(',')
            tuple(parts.collect { file(it.trim()) })
    }
    fastq_list_ch.view { "fastq_list_ch → $it" } 
    
    /*
    * ETAPE 4 : FILTER
    */
    if (params.filter) {
        FILTER(fastq_list_ch, params.expected_lengths)
        fastq_for_lotus = FILTER.out.filtered_out
        fastq_grouped_ch = fastq_for_lotus
            .collect() // pour donner tout en même temps
            .map { list -> list.flatten() }
    } else {
        fastq_grouped_ch = fastq_list_ch
            .collect()
            .map { list -> list.flatten() }
    }
    fastq_grouped_ch.view { "fastq_grouped_ch → $it" }

    /*
    * ETAPE 5 : ANALYSE TAXO
    */
    
    // NEXTITS

    /*
    * ETAPE 5 : REPORT
    */

}