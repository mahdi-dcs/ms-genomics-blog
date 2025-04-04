process bam_generation {
    queue 'nf-pipeline-pool-STANDARD_D4_V5-dev'
    tag "$sample_id"
    // container 'quay.io/biocontainers/samtools:1.17--h00cdaf9_0'
    container 'genomicsacrdev01.azurecr.io/biocontainers-samtools:1.17--h00cdaf9_0'
    publishDir "${params.outdir}/$sample_id/align/", mode: 'copy'


    input:
        tuple val(sample_id), path("${sample_id}.sam"), path(reference)

    output:
        tuple(val(sample_id), path("${sample_id}.bam"), path("${sample_id}.bam.bai"), path(reference, includeInputs: true) , emit: alignment_index)
        tuple(val(sample_id), path("${sample_id}.bam"), path("${sample_id}.bam.bai") , emit: coverage_index)
        tuple(val(sample_id), path("*.flagstat"), emit: flagstat)
        path "versions.yml"                                             , emit: versions



    script:
    """
    if [ -s "${sample_id}.sam" ]; then
        samtools sort  "${sample_id}.sam" -o "${sample_id}.bam"
        samtools index -@${task.cpus} "${sample_id}.bam"
        samtools flagstat "${sample_id}.bam" > "${sample_id}.flagstat"
    else
        touch "${sample_id}.bam" "${sample_id}.bam.bai" "${sample_id}.flagstat"
    fi
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}