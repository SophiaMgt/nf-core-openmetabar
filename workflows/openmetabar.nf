/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_openmetabar_pipeline'

// IMPORT LOCAL MODULES
//include { PARSE_FILE             } from '../modules/local/parse_file'

// IMPORT LOCAL SUBWORKFLOW
include { DEMULTIPLEX            } from '../subworkflows/local/demultiplex'
include { PARSE_WORFLOW          } from '../subworkflows/local/parse_file'
include { CLUSTER_TAXO           } from '../subworkflows/local/cluster_taxo'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow OPENMETABAR {

    take:
    ch_design

    main:

    ch_versions = Channel.empty()

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'openmetabar_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // ETAPE 1 : PARSE FILE
    //
    PARSE_WORFLOW(
        ch_design
    )
    fastq_list_ch  = PARSE_WORFLOW.out.fastq_list
    need_demux_ch  = PARSE_WORFLOW.out.needs_demux
    barcode_file_ch = PARSE_WORFLOW.out.barcode_file

    // Étape 2 : si besoin, lancer le démultiplexage
    fastq_to_demux_ch = need_demux_ch
        .combine(fastq_list_ch)
        .filter { demux_flag, fastq -> demux_flag }
        .map { demux_flag, fastq -> fastq }

    DEMULTIPLEX(
        fastq_to_demux_ch, 
        barcode_file_ch
    )
    fastq_for_lotus = DEMULTIPLEX.out.minibar_out

    Channel
        .fromPath(params.refDB)
        .set { db_ch }
    Channel
        .fromPath(params.tax4refDB)
        .set { tax_ch }
    
    CLUSTER_TAXO(
        fastq_for_lotus,
        db_ch,
        tax_ch
    )
    

    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


