//
// HBV workflow
//

//
// MODULE: Load modules
//
include { fastqc } from '../modules/fastqc'
include { fastp } from '../modules/fastp'
include { seqtk } from '../modules/seqtk'
include { blast } from '../modules/blast'
include { alignment_hbv } from '../modules/alignment_hbv'
include { bam_generation } from '../modules/bam_generation'
include { coverage_hbv } from '../modules/coverage_hbv'
include { plot_coverage_regions } from '../modules/plot_coverage_regions'
include { call_snvs_hbv } from '../modules/call_snvs_hbv'
include { call_deletions_hbv } from '../modules/call_deletions_hbv'
include { vcf_concat } from '../modules/vcf_concat'
include { vcf_uniq } from '../modules/vcf_uniq'
include { call_annotation } from '../modules/call_annotation'
include { annotation_extractfields } from '../modules/annotation_extractfields'
include { variants_long_table } from '../modules/variants_long_table'
include { dumpsoftwareversions } from '../modules/dumpsoftwareversions'
include { multiqc } from '../modules/multiqc'


workflow HBV {
    take:
    ch_tuple
    versions
    multiqc_config
    multiqc_logo

    main:
    ch_versions = Channel.empty()
    referenceBase = params.genomes['hbv'].referenceBase 
    //referenceGenbank = params.genomes['hbv'].referenceGenbank 
    ampliconBed = params.genomes['hbv'].ampliconBed 
    snpeff_database = params.genomes['hbv'].snpeff_database 
    snpeff_config = params.genomes['hbv'].snpeff_config 
    resistance_mutations_file = params.genomes['hbv'].resistance_mutations_file 
    multibase_codon_file = params.genomes['hbv'].multibase_codon_file
    
    hbv_blast = 'az://nextflow/nextflow-references/blast_db'
    ch_tuple | map {meta , reads -> [reads[0], reads[1]]} | set {ch_reads}
    seqtk(ch_reads)
    ch_versions = ch_versions.mix(seqtk.out.versions)

    blast(seqtk.out.fastx,  hbv_blast )
    ch_versions = ch_versions.mix(blast.out.versions)

    // QC fastq files
    fastqc(ch_reads)
    ch_versions = ch_versions.mix(fastqc.out.versions)
    fastp(ch_reads)
    ch_versions = ch_versions.mix(fastp.out.versions)

   blast.out.hbv_version
    .branch {
        hbv_version ->
        BLAST_PASS: hbv_version[1].countLines() >= 1
        BLAST_FAIL: hbv_version[1].countLines() < 1
    }
    .set { genome_blast_branch }

    // Don't proceeed further if no blast found
    genome_blast_branch.BLAST_FAIL.view { "There was (${it[2]}) genomes that matched for BLAST. Check blast results for details"}

    genome_blast_branch.BLAST_PASS
            .map{ it -> [ it[0], it[1] ] }
            .set { hbv_version }

    // Merge
    ch_concat_fastq= fastp.out.fastqs.join(hbv_version,  by: [0])

    // Align
    alignment_hbv(ch_concat_fastq, referenceBase)
    ch_versions = ch_versions.mix(alignment_hbv.out.versions)

    bam_generation(alignment_hbv.out.sam)
    ch_versions = ch_versions.mix(bam_generation.out.versions)

    // Merge
    ch_concat_bam = bam_generation.out.coverage_index.join(blast.out.hbv_version,  by: [0])

    // Coverge
    coverage_hbv(ch_concat_bam, ampliconBed)
    ch_versions = ch_versions.mix(coverage_hbv.out.versions)

    plot_coverage_regions(coverage_hbv.out.regions_bed)
    //ch_versions = ch_versions.mix(plot_coverage_regions.out.versions)

    // SNVs
    call_snvs_hbv(bam_generation.out.alignment_index, ampliconBed)
    ch_versions = ch_versions.mix(call_snvs_hbv.out.versions)

    // INDELs
    call_deletions_hbv(ch_concat_fastq, referenceBase)
    ch_versions = ch_versions.mix(call_deletions_hbv.out.versions)

    ch_concat_vcf = call_snvs_hbv.out.snv.join(call_deletions_hbv.out.indel,  by: [0])

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
    ch_annotation_outputs = annotation_extractfields.out.txt.join(call_annotation.out.report,  by: [0], failOnMismatch: false, failOnDuplicate: true)
    ch_annotation_outputs = ch_annotation_outputs.join(coverage_hbv.out.per_base_bed,  by: [0], failOnMismatch: false, failOnDuplicate: true)
    // variants_long_table(annotation_extractfields.out.txt, call_annotation.out.report, resistance_mutations_file, multibase_codon_file)
    variants_long_table(ch_annotation_outputs, resistance_mutations_file, multibase_codon_file)
    ch_versions = ch_versions.mix(variants_long_table.out.versions)

    // Report
    ch_versions = ch_versions.mix(versions)
    dumpsoftwareversions(ch_versions.unique().collectFile(name: 'collated_versions.yml'))
    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(fastp.out.json)
    ch_multiqc_files = ch_multiqc_files.mix(fastqc.out.zip)
    ch_multiqc_files = ch_multiqc_files.mix(blast.out.sequence_freq)
    ch_multiqc_files = ch_multiqc_files.mix(bam_generation.out.flagstat)
    ch_multiqc_files = ch_multiqc_files.mix(call_annotation.out.report)
    ch_multiqc_files = ch_multiqc_files.mix(coverage_hbv.out.global_txt)
    ch_multiqc_files = ch_multiqc_files.mix(coverage_hbv.out.summary_txt)
    ch_multiqc_files = ch_multiqc_files.mix(coverage_hbv.out.regions_txt)
    ch_multiqc_files = ch_multiqc_files.mix(plot_coverage_regions.out.heatmap_tsv)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.csv)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.txt_region)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.txt_impact)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.txt_type)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.txt_class)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.txt_quality)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.multichange_codons)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.non_RT_csv)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.drug_resistance_csv)
    ch_multiqc_files = ch_multiqc_files.mix(variants_long_table.out.insertion_deletion_csv)
    
    ch_multiqc_files.groupTuple( by:[0] ).map { meta, files -> [ meta, files.flatten() ] }.set{ch_samples}

    version_yaml = dumpsoftwareversions.out.collected_mqc_versions.collect()

    multiqc(ch_samples, multiqc_config, version_yaml,  multiqc_logo)

    emit:
    version_yaml
}