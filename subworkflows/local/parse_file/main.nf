// subworkflows/local/parse_file/main.nf
include { PARSE_FILE } from '../../../modules/local/parse_file/main'

workflow PARSE_WORFLOW {
    take:
    design_file

    main:
    PARSE_FILE(design_file)

    //
    // Convertir fastq_paths.txt -> Channel<path> (un path par élément)
    //
    ch_fastq = PARSE_FILE.out.fastq_paths
        .splitText()          // splitText lit le fichier ligne à ligne
        .map { line -> line.trim() }
        .filter { it }        // retirer lignes vides
        .map { pathStr ->
            def p = file(pathStr)
            if (!p.exists()) log.warn "[WARN] FASTQ not found: ${pathStr}"
            return p
        }
        .unique()


    //
    // barcode_file est déjà un path s'il existe ; on le renvoie tel quel
    //
    ch_barcode = PARSE_FILE.out.barcode_file
    ch_design = PARSE_FILE.out.design_file

    emit:
    fastq_list  = ch_fastq
    barcode_file = ch_barcode
    design_file = ch_design
}