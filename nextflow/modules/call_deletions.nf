process call_deletions {
    queue 'nf-pool1-STANDARD_D4_V3-prd'
    tag "$sample_id"
    publishDir "${params.outdir}/$sample_id/variants/", mode: 'copy'
    // container 'quay.io/biocontainers/medaka:1.4.4--py38h130def0_0'
    container 'phcccgenacrprd.azurecr.io/biocontainers-medaka:1.4.4--py38h130def0_0'


    input:
        tuple val(sample_id), path("${sample_id}.fastq")
        path(reference)

    output:
    
    tuple(val(sample_id), path("${sample_id}.indel.vcf"),  path("genotype.txt"), emit: indel)
    path  "versions.yml"                            , emit: versions

    script:

    """
    echo "${reference}" | cut -f1 -d '.' > genotype.txt
    medaka_haploid_variant -r ${reference} -i "${sample_id}.fastq"

    mv medaka/medaka.annotated.vcf "${sample_id}.indel.vcf"

    # Versions #
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$(echo \$(medaka --version | sed 's/medaka //'))
    END_VERSIONS
    """
}