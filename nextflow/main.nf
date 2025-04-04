#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

multiqc_config          = file("$launchDir/assets/multiqc_config.yml", checkIfExists: true)
multiqc_logo            = file("$launchDir/assets/logo.png")

//
// MODULE: Load modules
//
include { combine_fastq } from './modules/combine_fastq'

//
// SUBWORKFLOWS: Load subworkflows
//

include { HBV } from './subworkflows/hbv'
include { CMV } from './subworkflows/cmv'

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



    subtype = Channel.empty() 
    
     // Conditional statement in the workflow

    combine_fastq.out.filtered | map { row -> [[genome: row[2]], [row[0], row[1]]] }
        | branch { meta, reads ->
        hbv: meta.genome == "hbv"
            return [ meta, reads ]
        cmv: meta.genome == "cmv"
            return [ meta, reads ]
    }
    | set { samples_split }

    // Split into two channels
    samples_split
        .hbv
        .filter{ it != null }
        .set { ch_hbv }
    samples_split
        .cmv
        .filter{ it != null }
        .set { ch_cmv }

    // Run each workflow
    HBV(ch_hbv, ch_versions, multiqc_config, multiqc_logo)
    CMV(ch_cmv, ch_versions, multiqc_config, multiqc_logo)
}

workflow.onComplete {

    println "Pipeline completed!"

}
