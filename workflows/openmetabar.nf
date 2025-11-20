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
include { FILTER                 } from '../subworkflows/local/filter'

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
    need_demux_ch  = PARSE_WORFLOW.out.needs_demux // enlever ça et mettre un params.demux = true or false si on veut demux ou non
    barcode_file_ch = PARSE_WORFLOW.out.barcode_file

    // Etape filtre du fastq si on veut
    // Ensuite selon la techno et marqueur
    // Si ont - idmabio -> demux minibar et dès qu'on a les fastq => on fait un fichier mapping file pour lancer ensuite lotus3

    // Étape 2 demux si idmabio
    // if (params.techno == 'ont' && params.maker == 'COI-idmabio' && params.demultiplexing == 'true') {
    //     DEMULTIPLEX(
    //         fastq_list_ch, 
    //         barcode_file_ch)
    //     fastq_to_filter = DEMULTIPLEX.out.minibar_out
    //     fastq_to_filter.view()
    // }

    fastq_to_demux_ch = need_demux_ch
        .combine(fastq_list_ch)
        .filter { demux_flag, fastq -> demux_flag }
        .map { demux_flag, fastq -> fastq }

    DEMULTIPLEX(
        fastq_to_demux_ch, 
        barcode_file_ch
    )
    fastq_to_filter = DEMULTIPLEX.out.minibar_out
    fastq_to_filter.view()

    files_ch = fastq_to_filter.flatMap { folder ->
        println "Dossier reçu : $folder"
        def files = new File(folder.toString()).listFiles()   // <-- .toString() ici
            .findAll { it.isFile() }                         // uniquement les fichiers
            .collect { it.toPath() }                         // renvoie des Path
        return files
    }
    //files_ch.view { fq -> "FASTQ FILE main SONT : $fq" }

    // Etape filtre
    FILTER(
        files_ch,
        params.expected_lengths
    )
    fastq_for_lotus = FILTER.out.filtered_out
    fastq_grouped_ch = fastq_for_lotus.collect()
    fastq_grouped_ch.view()

    Channel
        .fromPath(params.refDB)
        .set { db_ch }
    Channel
        .fromPath(params.tax4refDB)
        .set { tax_ch }
    
    CLUSTER_TAXO(
        ch_design,
        fastq_grouped_ch,
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


