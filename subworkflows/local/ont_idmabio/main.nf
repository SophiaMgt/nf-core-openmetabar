// subworkflows/local/ont_idmabio/main.nf

//include { DEMULTIPLEX        } from '../../../modules/local/demultiplex'
include { MINIBAR } from '../../../modules/local/minibar/main'

//include { PARSE_WORFLOW      } from '../subworkflows/local/parse_file'
include { PARSE_FILE } from '../../../modules/local/parse_file/main'

//include { MAPPING_FILE       } from '../subworkflows/local/mapping_file'
include { BUILD_MAPPING_FILE } from '../../../modules/local/lotus3/mapping_file'

//include { CLUSTER_TAXO       } from '../subworkflows/local/cluster_taxo'
include { LOTUS3  } from '../../../modules/local/lotus3/main'

include { FILTER             } from '../filter'
//include { REPORT             } from '../modules/local/report/main'
include { RESULT_TABLE } from '../../../modules/local/report/result_table'

workflow ONT_IDMABIO {

    take:
    ch_design
    expected_lengths
    db_ch
    tax_ch

    main:

    /*
    * ETAPE 1 : PARSE
    */
    PARSE_FILE(ch_design)
    barcode_file_ch = PARSE_FILE.out.barcode_file
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
    * ETAPE 2 : DEMULTIPLEX
    */
    if (params.demux) {
        MINIBAR(fastq_list_ch, barcode_file_ch)
        fastq_to_filter = MINIBAR.out.fastq_trim
    } else {
        fastq_to_filter = fastq_list_ch
    }
    //fastq_to_filter.view { "fastq_to_filter → $it" }

    /*
    * ETAPE 3 : TRANSFORM DOSSIER OUTPUT MINIBAR -> FICHIERS
    */

    files_ch = fastq_to_filter.flatMap { item ->
        if (item.isDirectory()) {
            return file("${item}/*.fastq")
        }
        else {
            return item
        }
    }
    //files_ch.view { "files_ch → $it" } 


    /*
    * ETAPE 4 : FILTER
    */
    if (params.length_filter) {
        FILTER(files_ch, params.expected_lengths)
        fastq_for_lotus = FILTER.out.filtered_out
        fastq_grouped_ch = fastq_for_lotus
            .collect() // pour donner tout en même temps
            .map { list -> list.flatten() }
    } else {
        fastq_grouped_ch = files_ch
            .collect()
            .map { list -> list.flatten() }
    }
    fastq_grouped_ch.view { "fastq_grouped_ch → $it" }

    /*
    * ETAPE 5 : ANALYSE TAXO
    */
    
    BUILD_MAPPING_FILE(fastq_grouped_ch, design_file)
    BUILD_MAPPING_FILE.out.mapping_file.view { "MAP → $it" }
    BUILD_MAPPING_FILE.out.fastq_folder.view { "FASTQ → $it" }

    LOTUS3(
        BUILD_MAPPING_FILE.out.mapping_file,
        BUILD_MAPPING_FILE.out.fastq_folder,
        db_ch,
        tax_ch
    )

    RESULT_TABLE(
        LOTUS3.out.otu_table,
        LOTUS3.out.otu_seq,
        LOTUS3.out.otu_taxo,
        LOTUS3.out.blast_result
    )

    /*
    * ETAPE 5 : REPORT
    */

}