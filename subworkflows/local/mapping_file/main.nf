// subworkflows/local/mapping_file/main.nf
include { BUILD_MAPPING_FILE } from '../../../modules/local/lotus3/mapping_file'

workflow MAPPING_FILE {
    take:
    fastq
    design

    main:

    mapping_proc = BUILD_MAPPING_FILE(fastq, design)
    mapping_proc.mapping_file1.view { "[DEBUG] insub : $it"}
    //mapping_proc.mapping_file2.view { "[DEBUG] insub : $it"}

    emit:
    fastq_folder  = BUILD_MAPPING_FILE.out.fastq_folder
    map1  = BUILD_MAPPING_FILE.out.mapping_file1
    //map2  = BUILD_MAPPING_FILE.out.mapping_file2
}