process coverage_hbv {
    queue 'nf-pool1-STANDARD_D4_V3-prd'
    tag "$sample_id"
    // container 'quay.io/biocontainers/mosdepth:0.3.3--hdfd78af_1'
    container 'phcccgenacrprd.azurecr.io/biocontainers-mosdepth:0.3.3--hdfd78af_1'
    publishDir "${params.outdir}/$sample_id/coverage/", mode: 'copy'


    input:
    tuple val(sample_id),  path(bam), path(bai), path("genome.txt")
    path(bed)

    output:
    tuple val(sample_id), path('*.global.dist.txt')      , emit: global_txt
    tuple val(sample_id), path('*.summary.txt')          , emit: summary_txt
    tuple val(sample_id), path('*.region.dist.txt')      , optional:true, emit: regions_txt
    tuple val(sample_id), path('*.per-base.d4')          , optional:true, emit: per_base_d4
    tuple val(sample_id), path('*.per-base.bed.gz')      , optional:true, emit: per_base_bed
    tuple val(sample_id), path('*.per-base.bed.gz.csi')  , optional:true, emit: per_base_csi
    tuple val(sample_id), path('*.regions.bed.gz')       , optional:true, emit: regions_bed
    tuple val(sample_id), path('*.regions.bed.gz.csi')   , optional:true, emit: regions_csi
    tuple val(sample_id), path('*.quantized.bed.gz')     , optional:true, emit: quantized_bed
    tuple val(sample_id), path('*.quantized.bed.gz.csi') , optional:true, emit: quantized_csi
    tuple val(sample_id), path('*.thresholds.bed.gz')    , optional:true, emit: thresholds_bed
    tuple val(sample_id), path('*.thresholds.bed.gz.csi'), optional:true, emit: thresholds_csi
    path  "versions.yml"                            , emit: versions

    shell:
    '''
    export subtype=\$(cat genome.txt)
    if [ "$subtype" != "none" ]; then
        mosdepth \\
            --threads !{task.cpus} \\
            --by !{bed}/$subtype.bed \\
            !{sample_id} \\
            !{bam}
    else
        touch !{sample_id}.global.dist.txt
        touch !{sample_id}.summary.txt
    fi


    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
        mosdepth: \$(mosdepth --version 2>&1 | sed 's/^.*mosdepth //; s/ .*\$//')
    END_VERSIONS
    '''
}