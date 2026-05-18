//
// Subworkflow with functionality to prepare data
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { LENGTHS_FILTER } from '../../../modules/local/filter/lengths'
include { QUALITY_FILTER } from '../../../modules/local/filter/qual'
include { FINALIZE_FILTER_NAME } from '../../../modules/local/filter/rename'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO FILTER DATA
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow FILTER {

  take:
  fastq
  expected_lengths
  min_q

  main:
  if (params.quality_filter) {
    QUALITY_FILTER(fastq, min_q)
    fastq_after_quality = QUALITY_FILTER.out.filtered_fastq
  } else {
    fastq_after_quality = fastq
  }

  if (params.length_filter) {
    LENGTHS_FILTER(fastq_after_quality, expected_lengths)
    fastq_after_length = LENGTHS_FILTER.out.filtered_fastq
  } else {
    fastq_after_length = fastq_after_quality
  }

  //if (params.coding_filter) {
  //
  //}

  // clean de nom de fichier ?
  FINALIZE_FILTER_NAME(fastq_after_length)

  emit: 
  //filtered_out = LENGTHS_FILTER.out.filtered_fastq
  filtered_out = FINALIZE_FILTER_NAME.out.filtered_fastq
}
