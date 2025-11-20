//
// Subworkflow with functionality to prepare data
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { LENGTHS_FILTER } from '../../../modules/local/filter/lengths'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO PREPARE DATA
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow FILTER {

  take:
  fastq_demux
  expected_lengths

  main:
  //   ch_input = minibar_dir.flatMap { dir ->
  //       Channel.fromPath("${dir}/*.fastq").map { fq ->
  //           tuple(fq, expected_lengths)
  //       }
  //   }.view { "DEBUG Filter: $it" }  // affiche ce qui sera envoyé au process

    //fastq_demux.view { fq -> "FASTQ FILE sub SONT : $fq" }

  LENGTHS_FILTER(fastq_demux,expected_lengths)

  emit: 
  filtered_out = LENGTHS_FILTER.out.filtered_fastq

}
