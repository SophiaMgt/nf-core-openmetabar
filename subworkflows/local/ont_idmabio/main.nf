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
    // PARSE_WORFLOW(
    //     ch_design
    // )
    // fastq_list_ch   = PARSE_WORFLOW.out.fastq_list
    // barcode_file_ch = PARSE_WORFLOW.out.barcode_file
    // design_file     = PARSE_WORFLOW.out.design_file

    PARSE_FILE(ch_design)
    // Convertir fastq_paths.txt -> Channel<path> (un path par élément)
    fastq_list_ch = PARSE_FILE.out.fastq_paths
        .splitText()          // splitText lit le fichier ligne à ligne
        .map { line -> line.trim() }
        .filter { it }        // retirer lignes vides
        .map { pathStr ->
            def p = file(pathStr)
            if (!p.exists()) log.warn "[WARN] FASTQ not found: ${pathStr}"
            return p
        }
        .unique()
    barcode_file_ch = PARSE_FILE.out.barcode_file
    design_file     = PARSE_FILE.out.design_file

    /*
    * ETAPE 2 : DEMULTIPLEX
    */
    if (params.demux) {
        MINIBAR(fastq_list_ch, barcode_file_ch)
        fastq_to_filter = MINIBAR.out.fastq_trim
    } else {
        fastq_to_filter = fastq_list_ch
    }

    /*
    * ETAPE 3 : TRANSFORM DOSSIER -> FICHIERS
    */
    files_ch = fastq_to_filter.flatMap { folder ->
        def files = new File(folder.toString())
            .listFiles()
            .findAll { it.isFile() }
            .collect { it.toPath() }
        return files
    }
    // files_ch = fastq_to_filter.flatMap { folder ->
    //     Channel.fromPath("${folder}/*.fastq")
    // }
    
    /*
    * ETAPE 4 : FILTER
    */
    FILTER(
        files_ch,
        expected_lengths
    )
    fastq_for_lotus = FILTER.out.filtered_out
    fastq_for_lotus.collect().set { fastq_grouped_ch } // pour donner tout en même temps
    
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

    /*
    * ETAPE 5 : REPORT
    */

}