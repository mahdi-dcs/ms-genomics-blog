//
// CMV workflow
//

//
// MODULE: Load modules
//
include { fastqc } from '../modules/fastqc'
include { fastp } from '../modules/fastp'
include { alignment } from '../modules/alignment'
include { bam_generation } from '../modules/bam_generation'
include { coverage } from '../modules/coverage'
include { plot_coverage_regions } from '../modules/plot_coverage_regions'
include { call_snvs } from '../modules/call_snvs'
include { call_deletions } from '../modules/call_deletions'
include { vcf_concat } from '../modules/vcf_concat'
include { vcf_uniq } from '../modules/vcf_uniq'
include { call_annotation } from '../modules/call_annotation'
include { annotation_extractfields } from '../modules/annotation_extractfields'
include { variants_long_table } from '../modules/variants_long_table'
include { dumpsoftwareversions } from '../modules/dumpsoftwareversions'
include { multiqc } from '../modules/multiqc'


workflow CMV {
    take:
    ch_tuple 
    versions
    multiqc_config
    multiqc_logo

    main:
    ch_versions = Channel.empty()
    referenceBase = params.genomes['cmv'].referenceBase 
    //referenceGenbank = params.genomes[genome].referenceGenbank 
    ampliconBed = params.genomes['cmv'].ampliconBed 
    snpeff_database = params.genomes['cmv'].snpeff_database 
    snpeff_config = params.genomes['cmv'].snpeff_config 
    resistance_mutations_file = params.genomes['cmv'].resistance_mutations_file 
    multibase_codon_file = params.genomes['cmv'].multibase_codon_file

    // QC fastq files
    ch_tuple | map {meta , reads -> [reads[0], reads[1]]} | set {ch_reads}
    fastqc(ch_reads)
    ch_versions = ch_versions.mix(fastqc.out.versions)
    fastp(ch_reads)
    ch_versions = ch_versions.mix(fastp.out.versions)


    // Align
    alignment(fastp.out.fastqs, referenceBase)
    ch_versions = ch_versions.mix(alignment.out.versions)

    bam_generation(alignment.out.sam)
    ch_versions = ch_versions.mix(bam_generation.out.versions)

    // Coverge
    coverage(bam_generation.out.coverage_index, ampliconBed)
    ch_versions = ch_versions.mix(coverage.out.versions)

    plot_coverage_regions(coverage.out.regions_bed)
    //ch_versions = ch_versions.mix(plot_coverage_regions.out.versions)

    // SNVs
    call_snvs(bam_generation.out.alignment_index, ampliconBed)
    ch_versions = ch_versions.mix(call_snvs.out.versions)

    // INDELs
    call_deletions(fastp.out.fastqs, referenceBase)
    ch_versions = ch_versions.mix(call_deletions.out.versions)

    ch_concat_vcf = call_snvs.out.snv.join(call_deletions.out.indel,  by: [0])

        // Merge and find uniq vcf
    vcf_concat(ch_concat_vcf)
    ch_versions = ch_versions.mix(vcf_concat.out.versions)
    vcf_uniq(vcf_concat.out.vcf)
    ch_versions = ch_versions.mix(vcf_uniq.out.versions)

    // Annotation
    call_annotation(vcf_uniq.out.vcf, snpeff_database,snpeff_config)
    ch_versions = ch_versions.mix(call_annotation.out.versions)
    annotation_extractfields(call_annotation.out.vcf)
    ch_versions = ch_versions.mix(annotation_extractfields.out.versions)

    // match annotation files based on sample name
    ch_annotation_outputs = annotation_extractfields.out.txt.join(call_annotation.out.report,  by: [0], failOnMismatch: true, failOnDuplicate: true)
    ch_annotation_outputs = ch_annotation_outputs.join(coverage.out.per_base_bed,  by: [0], failOnMismatch: true, failOnDuplicate: true)
    // variants_long_table(annotation_extractfields.out.txt, call_annotation.out.report, resistance_mutations_file, multibase_codon_file)
    variants_long_table(ch_annotation_outputs, resistance_mutations_file, multibase_codon_file)
    ch_versions = ch_versions.mix(variants_long_table.out.versions)


    // Report
    ch_versions = ch_versions.mix(versions)
    dumpsoftwareversions(ch_versions.unique().collectFile(name: 'collated_versions.yml'))
    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(fastp.out.json)
    ch_multiqc_files = ch_multiqc_files.mix(fastqc.out.zip)
    ch_multiqc_files = ch_multiqc_files.mix(bam_generation.out.flagstat)
    ch_multiqc_files = ch_multiqc_files.mix(call_annotation.out.report)
    ch_multiqc_files = ch_multiqc_files.mix(coverage.out.global_txt)
    ch_multiqc_files = ch_multiqc_files.mix(coverage.out.summary_txt)
    ch_multiqc_files = ch_multiqc_files.mix(coverage.out.regions_txt)
    ch_multiqc_files = ch_multiqc_files.mix(plot_coverage_regions.out.heatmap_tsv)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.csv)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.txt_region)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.txt_impact)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.txt_type)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.txt_class)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.txt_quality)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.multichange_codons)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.drug_resistance_csv)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.insertion_deletion_csv)

    ch_multiqc_files.groupTuple( by:[0] ).map { meta, files -> [ meta, files.flatten() ] }.set{ch_samples}

    version_yaml = dumpsoftwareversions.out.collected_mqc_versions.collect()

    multiqc(ch_samples, multiqc_config, version_yaml,  multiqc_logo)

    emit:
    version_yaml
}