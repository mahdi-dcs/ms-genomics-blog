process annotation_extractfields {
    queue 'nf-pool1-STANDARD_D4_V3-prd'
    tag "$sample_id"
    publishDir "${params.outdir}/$sample_id/annotation/", mode: 'copy'
    // container 'quay.io/biocontainers/snpsift:4.3.1t--hdfd78af_3'
    container 'phcccgenacrprd.azurecr.io/biocontainers-snpsift:4.3.1t--hdfd78af_3'

    input:
    tuple val(sample_id), path(vcf)
    

    output:
    tuple val(sample_id), path("*.snpsift.txt"), emit: txt
    path "versions.yml"                   , emit: versions


    script:
    def args = task.ext.args ?: ''

    def avail_mem = 4
    if (!task.memory) {
        log.info '[SnpSift] Available memory not known - defaulting to 4GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    """
    if [ -s $vcf ]; then
        SnpSift \\
            -Xmx${avail_mem}g \\
            extractFields \\
            -s "," \\
            -e "." \\
            $vcf \\
            CHROM POS REF AF QUAL DP4 ALT  \\
            "ANN[*].GENE" "ANN[*].GENEID" \\
            "ANN[*].IMPACT" "ANN[*].EFFECT" \\
            "ANN[*].FEATURE" "ANN[*].FEATUREID" \\
            "ANN[*].BIOTYPE" "ANN[*].RANK" "ANN[*].HGVS_C" \\
            "ANN[*].HGVS_P" "ANN[*].CDNA_POS" "ANN[*].CDNA_LEN" \\
            "ANN[*].CDS_POS" "ANN[*].CDS_LEN" "ANN[*].AA_POS" \\
            "ANN[*].AA_LEN" "ANN[*].DISTANCE" "EFF[*].EFFECT" \\
            "EFF[*].FUNCLASS" "EFF[*].CODON" "EFF[*].AA" "EFF[*].AA_LEN" \\
            > ${sample_id}.snpsift.txt
    else
        touch ${sample_id}.snpsift.txt
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snpsift: \$( echo \$(SnpSift split -h 2>&1) | sed 's/^.*version //' | sed 's/(.*//' | sed 's/t//g' )
    END_VERSIONS
    """
}