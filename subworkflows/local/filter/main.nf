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
    SUBWORKFLOW TO FILTER DATA
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow FILTER {

  take:
  fastq
  expected_lengths
  //qual

  main:
  //   ch_input = minibar_dir.flatMap { dir ->
  //       Channel.fromPath("${dir}/*.fastq").map { fq ->
  //           tuple(fq, expected_lengths)
  //       }
  //   }.view { "DEBUG Filter: $it" }  // affiche ce qui sera envoyé au process

    //fastq_demux.view { fq -> "FASTQ FILE sub SONT : $fq" }

  //if (params.length_filter) {
    //LENGTHS_FILTER(fastq,expected_lengths)
  //}
  LENGTHS_FILTER(fastq,expected_lengths)
  //if (params.qual_filter) {
   // QUAL_FILTER(fastq,qual)
  //}

  //if (params.coding_filter) {
  //
  //}

  emit: 
  filtered_out = LENGTHS_FILTER.out.filtered_fastq

}
