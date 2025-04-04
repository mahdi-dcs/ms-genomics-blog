process alignment {
    queue 'nf-pool1-STANDARD_D4_V3-prd'

    tag "$sample_id"
    // container 'quay.io/biocontainers/minimap2:2.17--hed695b0_3'
    container 'phcccgenacrprd.azurecr.io/biocontainers-minimap2:2.17--hed695b0_3'

    publishDir "${params.outdir}/$sample_id/align/", mode: 'copy'

    input:
        tuple val(sample_id),  path(reads)
        path(reference)

    output:
        tuple(
            val(sample_id),
            path("${sample_id}.sam"),
            path("*fa", includeInputs: true),
            emit: sam)
         path "versions.yml"                                             , emit: versions

    script:
    """
    minimap2 -t "${task.cpus}" -ax map-ont "${reference}" "${reads}" > "${sample_id}.sam"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """
}