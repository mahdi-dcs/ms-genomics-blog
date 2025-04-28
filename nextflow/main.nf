#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Load modules
//
include { combine_fastq } from './modules/combine_fastq'

//
// SUBWORKFLOWS: Load subworkflows
//

// main workflow
workflow {

    ch_versions = Channel.empty() 

    // load in the samples file
    samples = Channel
        .fromPath(params.samples_file)
        .splitCsv(header: true,  sep:',' )
        .map{ row-> tuple(row.sample_id, file(row.input_file), row.genome) }

    // Concat fastq's
    samples.groupTuple( by:[0] ).map { meta, reads, genome -> [ meta, reads.flatten(), genome.flatten().unique() ] }.set{ch_fastq}
    combine_fastq(ch_fastq)
    ch_versions = ch_versions.mix(combine_fastq.out.versions)
    
}

workflow.onComplete {

    println "Pipeline completed!"

}
