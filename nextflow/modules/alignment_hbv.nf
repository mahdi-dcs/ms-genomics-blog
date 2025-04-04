process alignment_hbv {
    queue 'nf-pool1-STANDARD_D4_V3-prd'

    tag "$sample_id"
    // container 'quay.io/biocontainers/minimap2:2.17--hed695b0_3'
    container 'phcccgenacrprd.azurecr.io/biocontainers-minimap2:2.17--hed695b0_3'
    publishDir "${params.outdir}/$sample_id/align/", mode: 'copy'

    input:
        tuple val(sample_id), path(reads), path("genome.txt")
        path(reference)

    output:
        tuple(
            val(sample_id),
            path("${sample_id}.sam"),
            path("*fasta"),
            emit: sam)
         path "versions.yml"                                             , emit: versions

    shell:
    '''
    export subtype=\$(cat genome.txt)
    if [ "\$subtype" != "none" ]; then
        minimap2 -t "!{task.cpus}" -ax map-ont "!{reference}/\$subtype.fasta" "!{reads}" > "!{sample_id}.sam"
        mv "!{reference}/\$subtype.fasta" .
    else
        echo "Skipping minimap2 as genome is 'none'"
        touch "!{sample_id}.sam"
        touch "none.fasta"

    fi
    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    '''
}