process vcf_concat {
    queue 'nf-pipeline-pool-STANDARD_D4_V5-dev'
    tag "$sample_id"
    publishDir "${params.outdir}/$sample_id/variants/", mode: 'copy'
    // container "quay.io/biocontainers/bcftools:1.17--haef29d1_0"
    container "genomicsacrdev01.azurecr.io/biocontainers-bcftools:1.17--haef29d1_0"

    input:
    tuple val(sample_id), path("${sample_id}.snv.vcf"), path("${sample_id}.indel.vcf"), path("genotype.txt")

    output:
    tuple val(sample_id), path("${sample_id}.vcf"), path("genotype.txt", includeInputs: true), emit: vcf
    path  "versions.yml"         , emit: versions


    script:
    """
    if [ -s ${sample_id}.snv.vcf ]; then
        bgzip -c ${sample_id}.snv.vcf > ${sample_id}.snv.vcf.gz
        bcftools index -t ${sample_id}.snv.vcf.gz
        bgzip -c ${sample_id}.indel.vcf > ${sample_id}.indel.vcf.gz
        bcftools index -t ${sample_id}.indel.vcf.gz

        bcftools merge \\
            --output concat.vcf.gz \\
            --threads $task.cpus \\
            ${sample_id}.snv.vcf.gz ${sample_id}.indel.vcf.gz

        bcftools \\
            sort \\
            --output ${sample_id}.vcf \\
            --temp-dir . \\
            --output-type b \\
            concat.vcf.gz
    else
        touch ${sample_id}.vcf
    fi


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}