##########
# Plot X and Y intensity and X heterozygosity for gender check
# Usage: R --args config.file < gender_plot.R
##########

library(GWASTools)
library(QCpipeline)
sessionInfo()

# read configuration
args <- commandArgs(trailingOnly=TRUE)
if (length(args) < 1) stop("missing configuration file")
config <- readConfig(args[1])

# check config and set defaults
required <- c("annot_scan_file", "annot_snp_file", "nc_geno_file", "out_het_file", "out_inten_file")
optional <- c("annot_scan_sexCol", "out_pdf")
default <- c("sex", "sex_check.pdf")
config <- setConfigDefaults(config, required, optional, default)
print(config)

(scanAnnot <- getobj(config["annot_scan_file"]))

# mean intensity
mninten <- getobj(config["out_inten_file"])
mninten <- mninten[[1]] # only want sum of X and Y intensities
stopifnot(allequal(getScanID(scanAnnot), rownames(mninten)))

# heterozygosity
het <- getobj(config["out_het_file"])
stopifnot(allequal(getScanID(scanAnnot), rownames(het)))

# plot colors
sex <- getVariable(scanAnnot, config["annot_scan_sexCol"])
if (is.null(sex)) {
  stop(paste("sex variable", config["annot_scan_sexCol"], "not found in annotation"))
}
if (!all(sex %in% c("M", "F"))) {
  stop("sex must be coded as M/F")
}
plotcol <- rep(NA, nrow(scanAnnot))
plotcol[sex == "F"] <- "red"
plotcol[sex == "M"] <- "blue"

# plot labels - X and Y probes
(snpAnnot <- getobj(config["annot_snp_file"]))
chr <- getChromosome(snpAnnot, char=TRUE)
nx <- sum(chr == "X")
ny <- sum(chr == "Y")
xlab <- paste("X intensity (",nx," probes)", sep="")
ylab <- paste("Y intensity (",ny," probes)", sep="")

# best guess at real sex
# only used for plotting anomalous points on top
male <- mninten[,"Y"] > 0.5 & mninten[,"X"] < 1.0
anom <- (male & sex == "F") | (!male & sex == "M")

# plot
pdf(file=config["out_pdf"], width=8, height=8)
par(mfrow=c(2,2))

# X vs Y intensity
plot(mninten[,"X"], mninten[,"Y"], col=plotcol, xlab=xlab, ylab=ylab)
points(mninten[anom,"X"], mninten[anom,"Y"], col=plotcol[anom])
legend(bestLegendPos(mninten[,"X"], mninten[,"Y"]), c("M","F"), col=c("blue","red"), pch=c(1,1))

# Het on X vs X intensity
plot(mninten[,"X"], het[,"X"], col=plotcol, xlab=xlab, ylab="X heterozygosity")
points(mninten[anom,"X"], het[anom,"X"], col=plotcol[anom])

# Het on X vs Y intensity
plot(mninten[,"Y"], het[,"X"], col=plotcol, xlab=ylab, ylab="X heterozygosity")
points(mninten[anom,"Y"], het[anom,"X"], col=plotcol[anom])

# X vs A het (females only)
sel <- sex == "F"
plot(het[sel,"A"], het[sel,"X"], col="red", xlab="Autosomal heterozygosity", ylab="X heterozygosity")
points(het[(sel & anom),"A"], het[(sel & anom),"X"], col=plotcol[sel & anom])
dev.off()