process call_deletions_hbv {
    queue 'nf-pool1-STANDARD_D4_V3-prd'
    tag "$sample_id"
    publishDir "${params.outdir}/$sample_id/variants/", mode: 'copy'
    // container 'quay.io/biocontainers/medaka:1.4.4--py38h130def0_0'
    container 'phcccgenacrprd.azurecr.io/biocontainers-medaka:1.4.4--py38h130def0_0'

    input:
        tuple val(sample_id), path("${sample_id}.fastq"), path("genome.txt")
        path(reference)

    output:
    
    tuple(val(sample_id), path("${sample_id}.indel.vcf"),  path("genotype.txt"), emit: indel)
    path  "versions.yml"                            , emit: versions


    shell:

    '''
    if [ "$(cat genome.txt)" != "none" ]; then
        export subtype=$(cat genome.txt)
        cp genome.txt genotype.txt
        medaka_haploid_variant -r !{reference}//$subtype.fasta -i "!{sample_id}.fastq"

        mv medaka/medaka.annotated.vcf "!{sample_id}.indel.vcf"

        

    else
        touch "!{sample_id}.indel.vcf"
        touch "genotype.txt"
        touch "versions.yml"
    fi

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
        medaka: $(echo $(medaka --version | sed 's/medaka //'))
    END_VERSIONS
    '''
}