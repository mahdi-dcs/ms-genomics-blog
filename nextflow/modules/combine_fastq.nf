process combine_fastq {
    queue 'nf-pool1-STANDARD_D4_V3-prd'
    tag "$sample_id"
    // container 'ontresearch/wf-artic:shaa5485f2d1c9085c23b266273556a4ce01e5e0dd9'
    container 'phcccgenacrprd.azurecr.io/ontresearch-wf-artic:20241129pull'
    publishDir "${params.outdir}/$sample_id/combinedFastq/", mode: 'copy'

    input:
        tuple val(sample_id), path(reads, stageAs: "input/*"), val(genome)

    output:
        tuple( val(sample_id),path("${sample_id}.fastq"),val("${genome[0]}"), emit: filtered)
        tuple(
            val(sample_id),
            path("${sample_id}.stats"),
            emit: stats)
        path "versions.yml"                                     , emit: versions

    shell:
    """
    fastcat \
        -s "${sample_id}" \
        -r "${sample_id}.stats" \
        -x input > "${sample_id}.fastq"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastcat: \$(fastcat -V 2>&1)
    END_VERSIONS
    """
}