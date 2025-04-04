process seqtk {
    queue 'nf-pool1-STANDARD_D4_V3-prd'
    tag "$sample_id"
    // container 'quay.io/biocontainers/seqtk:1.4--he4a0461_1'
    container 'phcccgenacrprd.azurecr.io/biocontainers-seqtk:1.4--he4a0461_1'
    publishDir "${params.outdir}/${sample_id}/fasta/", mode: 'copy'                              

    input:
        tuple val(sample_id),  file(reads)

    output:
        tuple val(sample_id), path("*.fasta")     , emit: fastx
        path "versions.yml"               , emit: versions

    script:
    """
    seqtk \\
        seq -A \\
        $reads > ${sample_id}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqtk: \$(echo \$(seqtk 2>&1) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """
}