process fastp {
    queue 'nf-pipeline-pool-STANDARD_D4_V3-dev'
    
    tag "$sample_id"
    // container 'quay.io/biocontainers/fastp:0.23.2--h79da9fb_0'
    container 'phcccgenacrprd.azurecr.io/biocontainers-fastp:0.23.2--h79da9fb_0'
    publishDir "${params.outdir}/${sample_id}/fastp/", mode: 'copy'

    input:
        tuple val(sample_id),  file(reads)

    output:
        tuple val(sample_id), path("${sample_id}.fastp.trimmed.fq.gz") , emit: fastqs
        tuple val(sample_id), path("${sample_id}.fastp.json") , emit: json
        tuple val(sample_id), path('*.html')           , emit: html
        path "versions.yml"                                     , emit: versions

    script:
    """
    fastp \
        -i ${reads} \
        -q 10 \
        -l 100 \
        -o ${sample_id}.fastp.trimmed.fq.gz \
        --json ${sample_id}.fastp.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
    END_VERSIONS
    """
}