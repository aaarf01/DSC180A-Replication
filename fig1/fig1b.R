# Fig. 1B of Martiny et al. (2026, Sci. Adv.): random forest R^2 for theta' predicted from the
# nutricline alone vs nutricline + genomic stress biomarkers (published bars ~0.36 and ~0.62).
# Runs the authors' script UNCHANGED (authors_code/random_forest_analysis_v2.R, md5-checked) and
# records the values. Nothing is edited, filtered or re-fitted.
#
# Run from anywhere:   Rscript fig1/fig1b.R      (or let fig1/run_fig1.m / run_all.m call it)
# Outputs (fig1/outputs/): fig1b_run_log.txt, fig1b_results.csv, fig1b_plots.pdf

locate_dirs <- function() {
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) { fig <- dirname(normalizePath(f)); return(list(fig = fig, root = dirname(fig))) }
  if (file.exists("authors_code")) return(list(fig = file.path(getwd(), "fig1"), root = getwd()))
  if (file.exists("../authors_code")) return(list(fig = getwd(), root = normalizePath("..")))
  stop("Run this script from the repository root or from fig1/.")
}
d <- locate_dirs()
out <- file.path(d$fig, "outputs"); dir.create(out, showWarnings = FALSE)
setwd(d$root)   # the authors' script reads data/... relative to the repository root

required <- c("randomForest", "reshape", "ggplot2", "pdp")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install these R packages first: install.packages(c(",
       paste0('"', missing, '"', collapse = ", "), "))")
}

script <- file.path("authors_code", "random_forest_analysis_v2.R")
expected_md5 <- "1031f658426c7c4d52ee9abb2456e1a9"   # authors' v1.0.2 file
actual_md5 <- unname(tools::md5sum(script))

sink(file.path(out, "fig1b_run_log.txt"), split = TRUE)
cat("Fig. 1B run started:", format(Sys.time(), tz = "UTC", usetz = TRUE), "\n")
cat("Script md5:", actual_md5,
    if (identical(actual_md5, expected_md5)) "(matches authors' v1.0.2)" else "(DOES NOT MATCH - script was modified)", "\n\n")
if (!identical(actual_md5, expected_md5)) { sink(); stop("authors_code/random_forest_analysis_v2.R was modified") }

pdf(file.path(out, "fig1b_plots.pdf"), width = 8, height = 8)
ok <- tryCatch({
  source(script, echo = FALSE, print.eval = TRUE)   # authors' code, as published
  TRUE
}, error = function(e) {
  cat("\nERROR while running the authors' script:\n", conditionMessage(e), "\n")
  FALSE
})
dev.off()

if (ok) {
  n_total <- nrow(all_data_mod)
  cat("\n================ Fig. 1B results ================\n")
  cat("Rows in data_insitu_v2_25-04.csv:", n_total, "\n")
  cat("Paper states metagenomic n = 990 (logged discrepancy; no filtering applied)\n")
  cat("Final window: space =", space, "(2x2 degree), time =", time, "(+/-20 days)\n")
  cat("Samples used in final models (non-missing satellite theta'):", samp_count, "\n")
  cat("OOB R^2, nutricline only:        ", sprintf("%.4f", r2_nutricline_rf), "\n")
  cat("OOB R^2, nutricline + biomarkers:", sprintf("%.4f", r2_nut_gen_rf), "\n")
  cat("Ratio (full / nutricline):        ", sprintf("%.3f", r2_nut_gen_rf / r2_nutricline_rf), "\n")
  cat("Published (read off Fig. 1B bars): ~0.36 and ~0.62\n")
  cat("Our earlier run (R 4.4.1, randomForest 4.7-1.2): 0.3421 and 0.6051, n = 1091\n\n")
  cat("Known issue in authors' script (left unchanged): sat_data list slot 1 holds the\n",
      "'_1d' file, not '_1p'. Affects only column 1 of the matchup grid, not Fig. 1B.\n\n")
  cat("Matchup grid, OOB R^2 in % (rows = space slots 1..6; cols = +/-2..30 days):\n")
  print(nut_fits)
  cat("\nSample counts for the same grid:\n")
  print(samps)
  write.csv(data.frame(
    quantity = c("rows_in_insitu_file", "paper_stated_n", "n_final_models",
                 "oob_r2_nutricline", "oob_r2_nutricline_plus_genes"),
    value = c(n_total, 990, samp_count, r2_nutricline_rf, r2_nut_gen_rf)),
    file.path(out, "fig1b_results.csv"), row.names = FALSE)
}

cat("\n================ Software versions ================\n")
print(sessionInfo())
for (p in required) cat(p, as.character(packageVersion(p)), "\n")
cat("Paper used: R 4.2.1, randomForest 4.7.1.1\n")
sink()
