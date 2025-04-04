process variants_long_table {
    queue 'nf-pipeline-pool-STANDARD_D4_V3-dev'

    tag "$sample_id"
    publishDir "${params.outdir}/$sample_id/annotation/", mode: 'copy'
    // container 'quay.io/biocontainers/mulled-v2-77320db00eefbbf8c599692102c3d387a37ef02a:08144a66f00dc7684fad061f1466033c0176e7ad-0' 
    container 'phcccgenacrprd.azurecr.io/biocontainers-mulled-v2-77320db00eefbbf8c599692102c3d387a37ef02a:08144a66f00dc7684fad061f1466033c0176e7ad-0'

  
    input:
    tuple val(sample_id), path("snpsift/*"), path(annotations_report_file), path(per_base_bed_file)
    path(resistance_mutations_file)
    path(multibase_codon_file)
    // path(per_base_bed_file)
    // tuple val(sample_id), path(per_base_bed_file)

    output:
    tuple val(sample_id), path("${sample_id}_variants_long_table.csv")      , emit: csv
    tuple val(sample_id), path("${sample_id}_snpeff_variants_genomic_region.txt")      , emit: txt_region
    tuple val(sample_id), path("${sample_id}_snpeff_variants_effect_impact.txt")      , emit: txt_impact
    tuple val(sample_id), path("${sample_id}_snpeff_variants_effect_type.txt")      , emit: txt_type
    tuple val(sample_id), path("${sample_id}_snpeff_variants_functional_class.txt")      , emit: txt_class
    tuple val(sample_id), path("${sample_id}_snpeff_quality.txt")      , emit: txt_quality
    tuple val(sample_id), path("${sample_id}_multichange_codons.csv")      , emit: multichange_codons
    tuple val(sample_id), path("${sample_id}_non_RT_domain_variants.csv")      , emit: non_RT_csv
    tuple val(sample_id), path("${sample_id}_drug_resistance_mutations.csv"), emit: drug_resistance_csv
    tuple val(sample_id), path("${sample_id}_insertion_deletion_table.csv"), emit: insertion_deletion_csv

    path "versions.yml", emit: versions

    script:  // This script is bundled with the pipeline, in nf-core/viralrecon/bin/
    def args = task.ext.args ?: ''
    """
    if [ -s $annotations_report_file ]; then
        make_variants_long_table.py \\
            --snpsift_dir ./snpsift \\
            --snpeff_report_file $annotations_report_file \\
            --resistance_mutations $resistance_mutations_file \\
            --codonbases $multibase_codon_file \\
            --per_base_bed_file $per_base_bed_file \\
            $args
    else
        echo "Annotation report file is empty, skipping make_variants_long_table.py command."
    fi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}