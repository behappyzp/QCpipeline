##########
# Allele frequency
# Usage: R --args config.file < allele_freq.R
##########

library(GWASTools)
library(QCpipeline)
sessionInfo()

# read configuration
args <- commandArgs(trailingOnly=TRUE)
if (length(args) < 1) stop("missing configuration file")
config <- readConfig(args[1])

# check config and set defaults
required <- c("annot_scan_file", "geno_file")
optional <- c("out_afreq_file", "scan_exclude_file", "geno_subj_file")
default <- c("allele_freq.RData", NA, NA)
config <- setConfigDefaults(config, required, optional, default)
print(config)


# we want to use subject-level netcdf for allele frequency in snp_filters
# but sometimes allele frequency is run before there is a subject-level (ie chromosome anomalies)
# and sometimes it is run giving only *one* netcdf (the subject-level)
# so we need an if statement.
if (!is.na(config["geno_subj_file"])){
  data <- GenotypeReader(config["geno_subj_file"])
} else {
  data <- GenotypeReader(config["geno_file"])
}
data
scanAnnot <- getobj(config["annot_scan_file"])
# take subset of annotation to match netCDF
scanAnnot <- scanAnnot[match(getScanID(data), getScanID(scanAnnot)), ]
genoData <- GenotypeData(data, scanAnnot=scanAnnot)
scanID <- getScanID(genoData)


# are there any scans to exclude?
if (!is.na(config["scan_exclude_file"])) {
  scan.exclude <- getobj(config["scan_exclude_file"])
  #stopifnot(all(scan.exclude %in% scanID))
} else {
  scan.exclude <- NULL
}
length(scan.exclude)


afreq <- alleleFrequency(genoData, scan.exclude=scan.exclude)
save(afreq, file=config["out_afreq_file"])

close(genoData)
