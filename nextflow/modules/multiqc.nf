process multiqc {
    queue 'nf-pool1-STANDARD_D4_V3-prd'
    tag "$sample_id"
    // container 'quay.io/biocontainers/multiqc:1.25--pyhdfd78af_0'
    container 'phcccgenacrprd.azurecr.io/biocontainers-multiqc:1.25--pyhdfd78af_0'
    publishDir "${params.outdir}/$sample_id/report/", mode: 'copy'                              


    input:
        tuple val(sample_id), path(multiqc_files)
        path(multiqc_config)
        path(software_versions)
        path(multiqc_logo)

    output:
        path "*multiqc_report.html", emit: report
        path "*_data"              , emit: data
        path "*_plots"             , optional:true, emit: plots
        path "versions.yml"        , emit: versions

    script:
    def args = task.ext.args ?: ''
    custom_config_file = multiqc_config
    """
    multiqc -f $args -n ${sample_id}.multiqc_report.html .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """
}