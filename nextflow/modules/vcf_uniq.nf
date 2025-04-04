process vcf_uniq {
    queue 'nf-pool1-STANDARD_D4_V3-prd'
    tag "$sample_id"
    publishDir "${params.outdir}/$sample_id/variants/", mode: 'copy'
    // container 'quay.io/biocontainers/vcflib:1.0.3--hecb563c_1'
    container 'phcccgenacrprd.azurecr.io/biocontainers-vcflib:1.0.3--hecb563c_1'

    input:
    tuple val(sample_id), path(vcf), path ('genotype.txt')

    output:
    tuple val(sample_id), path("${sample_id}.vcf"),  path ('genotype.txt', includeInputs: true), emit: vcf
    path "versions.yml"          , emit: versions

    script:
    def VERSION = '1.0.3' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    if [ -s $vcf ]; then
        vcfuniq \\
            $vcf  > tmp.vcf 
            
        mv tmp.vcf ${sample_id}.vcf
    else
        touch ${sample_id}.vcf
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vcflib: $VERSION
    END_VERSIONS
    """
}