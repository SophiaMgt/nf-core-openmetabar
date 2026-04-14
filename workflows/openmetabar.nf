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
// include { DEMULTIPLEX            } from '../subworkflows/local/demultiplex'
// include { PARSE_WORFLOW          } from '../subworkflows/local/parse_file'
// include { MAPPING_FILE           } from '../subworkflows/local/mapping_file'
// include { CLUSTER_TAXO           } from '../subworkflows/local/cluster_taxo'
// include { FILTER                 } from '../subworkflows/local/filter'
// include { REPORT            } from '../modules/local/report/main'


include { ONT_IDMABIO             } from '../subworkflows/local/ont_idmabio'
// include { ONT_COI                 } from '../subworkflows/local/ont_coi'
include { PACBIO_LSU_ITS          } from '../subworkflows/local/pacbio_lsu_its'
include { PACBIO_16S              } from '../subworkflows/local/pacbio_16s'
include { ILLUMINA_LSU_ITS_16S    } from '../subworkflows/local/illumina_lsu_its_16s'


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

    // DB
    Channel
        .fromPath(params.refDB)
        .set { db_ch }
    Channel
        .fromPath(params.tax4refDB)
        .set { tax_ch }

    //
    // RE STRUCTURE
    //
    if (params.techno == 'ont' && (params.marker == 'COI-idmabio' || params.marker == '16s')) {
        ONT_IDMABIO(ch_design, params.expected_lengths, db_ch, tax_ch)
    } // OK
    
    if (params.techno == 'ont' && params.marker == 'COI') {
        ONT_COI(ch_design)
    }
    
    if (params.techno == 'pacbio' && (params.marker == 'LSU' || params.marker == 'ITS')) {
        PACBIO_LSU_ITS(ch_design, db_ch, tax_ch) // NextITS
    }

    if (params.techno == 'pacbio' && params.marker == '16s') {
        PACBIO_16S(ch_design, db_ch, tax_ch)
    } // OK

    if (params.techno == 'illumina') {
        ILLUMINA_LSU_ITS_16S(ch_design, db_ch, tax_ch)
    } // OK

/*
    //
    // ETAPE 1 : PARSE FILE
    //
    PARSE_WORFLOW(
        ch_design
    )
    fastq_list_ch  = PARSE_WORFLOW.out.fastq_list
    barcode_file_ch = PARSE_WORFLOW.out.barcode_file // besoin pour minibar et filtre barcode
    design_file = PARSE_WORFLOW.out.design_file

    // Etape filtre du fastq si on veut
    // Ensuite selon la techno et marqueur
    // Si ont - idmabio -> demux minibar et dès qu'on a les fastq => on fait un fichier mapping file pour lancer ensuite lotus3

    // Étape 2 demux si idmabio
    // if (params.techno == 'ont' && params.marker == 'COI-idmabio' && params.demultiplexing == 'true') {
    //     DEMULTIPLEX(
    //         fastq_list_ch, 
    //         barcode_file_ch)
    //     fastq_to_filter = DEMULTIPLEX.out.minibar_out
    //     fastq_to_filter.view()
    // }

    // POUR need_demux_ch
    // fastq_to_demux_ch = need_demux_ch
    //     .combine(fastq_list_ch)
    //     .filter { demux_flag, fastq -> demux_flag }
    //     .map { demux_flag, fastq -> fastq }
    // new new new new
    // Utiliser directement params.demux au lieu de need_demux_ch
    fastq_to_demux_ch = fastq_list_ch
        .filter { fastq -> params.demux }   

    DEMULTIPLEX(
        fastq_to_demux_ch, 
        barcode_file_ch
    )
    fastq_to_filter = DEMULTIPLEX.out.minibar_out //trim
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
    // fastq_for_lotus.view()  -> chaque fichier un après l'autre = channel STREAM
    fastq_for_lotus.collect().set { fastq_grouped_ch } // pour donner tout en même temps
    //fastq_grouped_ch.view { "GROUPE FASTQ : $it" }
    // [path1,path2,path3...]

    Channel
        .fromPath(params.refDB)
        .set { db_ch }
    Channel
        .fromPath(params.tax4refDB)
        .set { tax_ch }

    map_out = MAPPING_FILE(
                fastq_grouped_ch,
                design_file
            )
    map_out.map1.view { "output FILES to LOTUS3 → $it" }
    //map_out.map2.view { "output FILES to LOTUS3 → $it" }
    map_out.fastq_folder.view { "output FILES to LOTUS3 → $it" }

    // maps_ch = Channel
    //     .from([map_out.map1, map_out.map2])
    //     .flatMap { ch -> ch }

    // maps_ch.view { "[DEBUG] to CLUSTER_TAXO → $it" }

    // combined_ch = maps_ch.map { map_file -> 
    //     tuple(map_file, map_out.fastq_folder)
    // }

    // combined_ch.view { "[DEBUG] combined_ch going to CLUSTER_TAXO → $it" }

    CLUSTER_TAXO(
        map_out.map1,
        //map_out.map2,
        map_out.fastq_folder,
        db_ch,
        tax_ch
    )
*/
    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


