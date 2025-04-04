process dumpsoftwareversions {
    queue 'nf-pool1-STANDARD_D4_V3-prd'
    // container 'quay.io/biocontainers/multiqc:1.15--pyhdfd78af_0' 
    container 'phcccgenacrprd.azurecr.io/biocontainers-multiqc:1.15--pyhdfd78af_0' 

    input:
    path versions

    output:
    path "software_versions.yml"    , emit: yml
    path "software_versions_mqc.yml", emit: mqc_yml
    path "versions.yml"             , emit: versions
    path "collected_mqc_versions.yml", emit: collected_mqc_versions

    script:
    def args = task.ext.args ?: ''
    """
    echo $workflow.manifest.version > pipeline.version.txt
    echo $workflow.manifest.name > pipeline.name.txt
    echo $workflow.nextflow.version > nextflow.version.txt
    export NF_Version="\$(cat nextflow.version.txt)"
    export Pipe_Version="\$(cat pipeline.version.txt)"
    export Pipe_Name="\$(cat pipeline.name.txt)"
    cat $versions
    dumpsoftwareversions.py
    """
}