/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_openmetabar_pipeline'

// IMPORT LOCAL MODULES
include { PARSE_FILE             } from '../modules/local/parse_file'

// IMPORT LOCAL SUBWORKFLOW
include { DEMULTIPLEX            } from '../subworkflows/local/demultiplex'

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
    PARSE_FILE(
        ch_design
    )
    fastq_list_ch  = PARSE_FILE.out.fastq_list
    need_demux_ch  = PARSE_FILE.out.needs_demux
    barcode_file_ch = PARSE_FILE.out.barcode_file

    //
    // ETAPE 2 Lire la valeur true/false du fichier needs_demux.txt
    //
    demux_flag_ch = need_demux_ch.map { it.text.trim() == 'true' }

    //
    // Étape 3.v2 : filtrer les canaux pour DEMULPLEX uniquement si besoin
    //
    fastq_to_demux_ch = demux_flag_ch
        .combine(fastq_list_ch)
        .filter { demux_flag, fastq -> demux_flag }
        .map { demux_flag, fastq -> fastq }

    barcode_to_demux_ch = demux_flag_ch
        .combine(barcode_file_ch)
        .filter { demux_flag, barcode -> demux_flag }
        .map { demux_flag, barcode -> barcode }
    //
    // 3 Lancer DEMULPLEX uniquement si nécessaire
    //
    DEMULTIPLEX(
        fastq_to_demux_ch,
        barcode_to_demux_ch
    )
    fastq_demux_ch = DEMULTIPLEX.out.minibar_out



    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
