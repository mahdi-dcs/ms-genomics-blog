process call_annotation {
    queue 'nf-pipeline-pool-STANDARD_D4_V3-dev'
    tag "$sample_id"
    publishDir "${params.outdir}/$sample_id/annotation/", mode: 'copy'
    // container 'quay.io/biocontainers/snpeff:5.1--hdfd78af_2'
    container 'phcccgenacrprd.azurecr.io/biocontainers-snpeff:5.1--hdfd78af_2'

    input:
    tuple val(sample_id), path("${sample_id}.vcf"), path ("genotype.txt")
    path (data)
    path (snpeff_config)

    output:
    tuple val(sample_id), path("*.ann.vcf"), emit: vcf
    tuple(val(sample_id), path( "*.csv" ), emit: report)
    path "*.html"                     , emit: summary_html
    path "*.genes.txt"                , emit: genes_txt
    path "versions.yml"               , emit: versions

    shell:

    '''
    export subtype=\$(cat genotype.txt | cut -f1 -d '_')
    type=\$(cat genotype.txt)

    echo "subtype: \$subtype"

    # Check if the genotype is empty
    if [ -z "\$type" ]; then
        echo "Genotype is empty"
        touch "!{sample_id}.ann.vcf"
        touch "!{sample_id}.csv"
        touch "!{sample_id}.genes.txt"
        touch "!{sample_id}.html"

    else
        if [ "$subtype" = "cmv" ]; then
            export genotype=\$(cat snpEff.config | grep genome | grep -i $subtype | cut -f1 -d '.' | cut -f2 -d ' ')
        else
            export genotype=\$(cat snpEff.config | grep genome | grep -i hbv_$subtype | cut -f1 -d '.' | cut -f2 -d ' ')
        fi
       
        snpEff -Xmx6144g \\
            -c snpEff.config \\
            $genotype \\
            -csvStats "!{sample_id}.csv" \\
            -dataDir !{data} \\
            "!{sample_id}.vcf" \\
            > "!{sample_id}.ann.vcf"

    fi

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
        snpeff: \$(echo \$(snpEff -version 2>&1) | cut -f 2 -d ' ')
    END_VERSIONS
    '''

}