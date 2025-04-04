#!/usr/bin/env Rscript

################################################
################################################
## LOAD LIBRARIES                             ##
################################################
################################################

library(optparse)
library(ggplot2)
library(scales)
library(ComplexHeatmap)
library(viridis)
library(tidyverse)


################################################
################################################
## VALIDATE COMMAND-LINE PARAMETERS           ##
################################################
################################################

option_list <- list(make_option(c("-i", "--input_files"), type="character", default=NULL, help="Comma-separated list of mosdepth regions output file (typically end in *.regions.bed.gz)", metavar="input_files"),
                    make_option(c("-s", "--input_suffix"), type="character", default='.regions.bed.gz', help="Portion of filename after sample name to trim for plot title e.g. '.regions.bed.gz' if 'SAMPLE1.regions.bed.gz'", metavar="input_suffix"),
                    make_option(c("-o", "--output_dir"), type="character", default='./', help="Output directory", metavar="path"),
                    make_option(c("-p", "--output_suffix"), type="character", default='regions', help="Output suffix", metavar="output_suffix"),
                    make_option(c("-r", "--regions_prefix"), type="character", default=NULL, help="Replace this prefix from region names before plotting", metavar="regions_prefix"))

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

## Check input files
INPUT_FILES <- unique(unlist(strsplit(opt$input_files,",")))
if (length(INPUT_FILES) == 0) {
    print_help(opt_parser)
    stop("At least one input file must be supplied", call.=FALSE)
}
if (!all(file.exists(INPUT_FILES))) {
    stop(paste("The following input files don't exist:",paste(INPUT_FILES[!file.exists(INPUT_FILES)], sep='', collapse=' '), sep=' '), call.=FALSE)
}

## Check the output directory has a trailing slash, if not add one
OUTDIR <- opt$output_dir
if (tail(strsplit(OUTDIR,"")[[1]],1)!="/") {
    OUTDIR <- paste(OUTDIR,"/",sep='')
}
## Create the directory if it doesn't already exist.
if (!file.exists(OUTDIR)) {
    dir.create(OUTDIR,recursive=TRUE)
}

OUTSUFFIX <- trimws(opt$output_suffix, "both", whitespace = "\\.")

################################################
################################################
## READ IN DATA                               ##
################################################
################################################

## Read in data
dat <- NULL
if (length(INPUT_FILES) == 1 ) {
    for (input_file in INPUT_FILES) {
        sample = gsub(opt$input_suffix,'',basename(input_file))
        dat <- rbind(dat, read.delim(input_file, header=FALSE, sep='\t', stringsAsFactors=FALSE, check.names=FALSE), stringsAsFactors=F)
    }
}

## Reformat table
if (ncol(dat) == 5) {
    colnames(dat) <- c('chrom', 'start','end', 'region', 'coverage')
    if (!is.null(opt$regions_prefix)) {
        dat$region <- as.character(gsub(opt$regions_prefix, '', dat$region))
    }
    dat$region <- factor(dat$region, levels=unique(dat$region[order(dat$start)]))
    
} else {
    colnames(dat) <- c('chrom', 'start','end', 'coverage', 'sample')
}

## Write merged coverage data for all samples to file
outfile <- paste(OUTDIR,"all_samples.",OUTSUFFIX,".coverage.tsv", sep='')
write.table(dat, file=outfile, col.names=TRUE, row.names=FALSE, sep='\t', quote=FALSE)

################################################
################################################
## PER-SAMPLE COVERAGE PLOTS                  ##
################################################
################################################



################################################
################################################
## REGION-BASED HEATMAP ACROSS ALL SAMPLES    ##
################################################
################################################

if (ncol(dat) == 5 && length(INPUT_FILES) >= 1) {
    # mat <- dat[,c( "coverage")]
    mat <- dat$coverage
    mat <- t(as.matrix(mat))
    colnames(mat) <- dat$region
    mat1 <- data.frame(sample = c(sample),    # Append new column to front of data
                        mat)

    ## Write heatmap to file
    outfile <- paste(OUTDIR,OUTSUFFIX,".heatmap.tsv", sep='')
    write.table( mat1, file=outfile, row.names=FALSE, col.names=TRUE, sep="\t", quote=FALSE)
}

################################################
################################################
################################################
################################################
