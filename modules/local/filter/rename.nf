process FINALIZE_FILTER_NAME {

  tag "$fastq"

  input:
  path fastq

  output:
  path "*.filtered.fastq", emit: filtered_fastq

  script:
  """
  base=\$(basename "${fastq}" .fastq)

  base=\${base%.qual.length.coding}
  base=\${base%.qual.length}
  base=\${base%.qual.coding}
  base=\${base%.length.coding}
  base=\${base%.qual}
  base=\${base%.length}
  base=\${base%.coding}

  cp "${fastq}" "\${base}.filtered.fastq"
  """
}