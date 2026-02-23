#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

MAP="$1"
FASTQ_DIR="output_minibar"
OUT_DIR="fastq_trim"

mkdir -p "$OUT_DIR"

while IFS=$'\t' read -r sample bf primerF br primerR; do

    len_pf=${#primerF}
    len_pr=${#primerR}

    FASTQS=( "$FASTQ_DIR"/"$sample"*.fastq "$FASTQ_DIR"/"$sample"*.fastq.gz )
    [[ ${#FASTQS[@]} -eq 0 ]] && continue
    FASTQ="${FASTQS[0]}"

    echo "SAMPLE $sample"

    awk -v bf="$bf" -v br="$br" \
        -v len_pf="$len_pf" -v len_pr="$len_pr" \
        -v sample="$sample" '

    BEGIN {
        rc["A"]="T"; rc["T"]="A"; rc["C"]="G"; rc["G"]="C"
        for (i=length(bf); i>0; i--) rbf = rbf rc[substr(bf,i,1)]
        for (i=length(br); i>0; i--) rbr = rbr rc[substr(br,i,1)]
    }

    {
        h=$0; getline s; getline p; getline q

        orientation=""
        insert_start=insert_end=0

        # ---------- ORIENTATION FORWARD ----------
        if ((startF = index(s,bf)) && (startR = index(s,rbr))) {
            orientation="FORWARD"
            insert_start = startF + length(bf) + len_pf
            insert_end   = startR - len_pr
        }

        # ---------- ORIENTATION REVERSE ----------
        else if ((startF = index(s,br)) && (startR = index(s,rbf))) {
            orientation="REVERSE"
            insert_start = startF + length(br) + len_pr
            insert_end   = startR - len_pf
        }

        else next

        if (insert_start < 1 || insert_end <= insert_start) next

        insert_seq  = substr(s, insert_start, insert_end - insert_start + 1)
        insert_qual = substr(q, insert_start, insert_end - insert_start + 1)

        # ---------- DEBUG PRINT ----------
        print "DEBUG\t" sample \
              "\t" orientation \
              "\tstartF=" startF \
              "\tstartR=" startR \
              "\tinsert_start=" insert_start \
              "\tinsert_end=" insert_end \
              "\tlen=" length(insert_seq) \
              > "/dev/stderr"

        # ---------- OUTPUT FASTQ ----------
        print h
        print insert_seq
        print "+"
        print insert_qual
    }
    ' <( [[ "$FASTQ" == *.gz ]] && zcat "$FASTQ" || cat "$FASTQ" ) \
      > "$OUT_DIR/$sample.fastq"

done < "$MAP"