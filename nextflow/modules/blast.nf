process blast {
    queue 'nf-pool1-STANDARD_D4_V3-prd'
    tag "$sample_id"
    // container 'quay.io/biocontainers/blast:2.13.0--hf3cf87c_0'
    container 'phcccgenacrprd.azurecr.io/biocontainers-blast:2.13.0--hf3cf87c_0'
    publishDir "${params.outdir}/$sample_id/blast/", mode: 'copy'                              

    input:
    tuple val(sample_id), path(fasta)
    path  db

    output:
    tuple val(sample_id), path ("genome.txt"),  emit: hbv_version
    tuple val(sample_id), path ("sequence_freq.txt")         , emit: sequence_freq
    tuple val(sample_id), path ("${sample_id}_sequences.blastn.txt")         , emit: sequences
    
    path "versions.yml"               , emit: versions

    script:
    """
    blastn \\
        -db blast_db/HBVdb \\
        -query $fasta \\
        -out sequences.blastn.txt \\
        -outfmt 6 -evalue 0.00001 -word_size 7 -max_target_seqs 1
    
    # write the sequences.blastn.txt file to the output directory
    cp sequences.blastn.txt ${sample_id}_sequences.blastn.txt

    cut -f2 sequences.blastn.txt | sort | uniq -c | sort -r > sequence_freq.txt
    wc -l $fasta > sequences.blastn.txt
    
    sed 's/^[ \t]*//' sequence_freq.txt > sequence_f.txt

    if [ \$(wc -l < sequence_freq.txt) -eq 0 ]; then
        touch genome.txt
    else
        awk '{print \$2, \$1}' sequence_f.txt > temp_file
        mv temp_file sequence_freq.txt
        head -n 1 sequence_freq.txt | cut -f1 -d ' ' |  sed 's/azure/edit/' > genome.txt
        # Check if genome.txt is empty and add a message if no results are found
        if [ ! -s genome.txt ]; then
            touch genome.txt
        fi
        echo "subtype reads" | cat - sequence_freq.txt > temp_file
        mv temp_file sequence_freq.txt

        # add the percentage column to the sequence_freq.txt.
        sum=\$(awk '{s+=\$2} END {print s}' sequence_freq.txt)
        awk -v sum=\$sum '{print \$1, \$2, (\$2/sum)}' sequence_freq.txt > temp_file
        sed -i '1s/0/ Percentage/' temp_file
        mv temp_file sequence_freq.txt
    fi
    GENOME=\$(cat genome.txt)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(blastn -version 2>&1 | sed 's/^.*blastn: //; s/ .*\$//')
    END_VERSIONS
    """
}