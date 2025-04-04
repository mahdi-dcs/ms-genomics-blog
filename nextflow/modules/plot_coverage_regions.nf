process plot_coverage_regions {
    queue 'nf-pipeline-pool-STANDARD_D4_V3-dev'
    tag "$sample_id"
    publishDir "${params.outdir}/$sample_id/coverage/", mode: 'copy'

    // container 'quay.io/biocontainers/mulled-v2-ad9dd5f398966bf899ae05f8e7c54d0fb10cdfa7:05678da05b8e5a7a5130e90a9f9a6c585b965afa-0' 
    container 'phcccgenacrprd.azurecr.io/biocontainers-mulled-v2-ad9dd5f398966bf899ae05f8e7c54d0fb10cdfa7:05678da05b8e5a7a5130e90a9f9a6c585b965afa-0' 

    input:
    tuple val(sample_id), path(bed)

    output:
    tuple val(sample_id), path('*heatmap.tsv') , emit: heatmap_tsv

    script: // This script is bundled with the pipeline, in nf-core/viralrecon/bin/
    def args = task.ext.args ?: ''
    """
    plot_mosdepth_regions.r \\
        --input_files $bed \\
        --output_dir ./ \\
        --output_suffix mosdepth \\
        $args
    """
}