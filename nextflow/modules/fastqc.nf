process fastqc {
    queue 'nf-pipeline-pool-STANDARD_D4_V3-dev'

    tag "$sample_id"
    // container 'quay.io/biocontainers/fastqc:0.11.9--0'
    container 'phcccgenacrprd.azurecr.io/biocontainers-fastqc:0.11.9--0'
    publishDir "${params.outdir}/${sample_id}/fastqc/", mode: 'copy'


    input:
        tuple val(sample_id),  file(reads)

    output:
        tuple val(sample_id), path("*.html"), emit: html
        tuple val(sample_id), path("*.zip") , emit: zip
        path  "versions.yml"           , emit: versions

    script:

    """
    fastqc --threads $task.cpus $reads

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed -e "s/FastQC v//g" )
    END_VERSIONS
    """
}