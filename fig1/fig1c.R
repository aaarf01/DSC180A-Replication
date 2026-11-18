# Fig. 1C of Martiny et al. (2026, Sci. Adv.): "partial dependence of Theta' on individual
# elemental stress type". OUR RECONSTRUCTION: the authors released no code for this panel.
#
# Main reconstruction (variant C): classify each sample by its dominant stress type (the
# largest of the six Omega biomarkers), then average the Theta' residual left after the
# nutricline-only random forest. The residuals come from the authors' own script
# (random_forest_analysis_v2.R computes nutricline_rf_residual but never uses it), which
# this script sources unchanged. Variant C was chosen from four candidates tested in a
# Python prototype (signs 6/6, r = 0.98 with the published bars); all four are reported.
#
# Run from anywhere:   Rscript fig1/fig1c.R      (or let fig1/run_fig1.m / run_all.m call it)
# Outputs (fig1/outputs/): fig1c_run_log.txt, fig1c_results.csv, fig1c_bars.pdf

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

stopifnot(requireNamespace("randomForest", quietly = TRUE))
script <- file.path("authors_code", "random_forest_analysis_v2.R")
stopifnot(unname(tools::md5sum(script)) == "1031f658426c7c4d52ee9abb2456e1a9")

sink(file.path(out, "fig1c_run_log.txt"), split = TRUE)
cat("Fig. 1C reconstruction run:", format(Sys.time(), tz = "UTC", usetz = TRUE), "\n")
cat("Sourcing the authors' script unchanged (md5 verified); this refits the 90-model grid first.\n\n")
pdf(NULL)                                    # discard the authors' plots
invisible(capture.output(source(script, echo = FALSE)))
dev.off()

# Samples and residuals exactly as in the authors' script (2 x 2 degrees, +/-20 days)
resid <- all_data_mod_save$nutricline_rf_residual[samp]
theta <- nut_sat
om <- cbind(N_High = all_data_mod$Omega_N_High[samp], N_Med = all_data_mod$Omega_N_Med[samp],
            P_High = all_data_mod$Omega_P_High[samp], P_Med = all_data_mod$Omega_P_Med[samp],
            Fe_High = all_data_mod$Omega_Fe_High[samp], Fe_Med = all_data_mod$Omega_Fe_Med[samp])
stopifnot(length(resid) == nrow(om), !anyNA(resid))
cat("Samples:", nrow(om), "\n")

dom <- factor(colnames(om)[max.col(om, ties.method = "first")], levels = colnames(om))
cat("Samples per dominant stress type:\n"); print(table(dom))

# Published bars, read from the figure (approximate, about +/-0.02)
published <- c(N_High = -0.13, N_Med = 0.32, P_High = 0.20, P_Med = 0.15, Fe_High = -0.12, Fe_Med = -0.27)

# C (main): mean nutricline-model residual by dominant stress type, with standard errors
C  <- tapply(resid, dom, mean)
Cse <- tapply(resid, dom, function(x) sd(x) / sqrt(length(x)))

# B: mean residual over samples where each Omega > 0 (stress signal present)
B <- sapply(colnames(om), function(k) mean(resid[om[, k] > 0]))

# D: mean observed Theta' minus overall mean, by dominant type (no nutricline adjustment)
D <- tapply(theta, dom, mean) - mean(theta)

# A: classic partial dependence at Omega = 1 minus Omega = 0, from a random forest with
#    nutricline + all six Omegas (the published panel includes P medium)
X7 <- cbind(nitri = all_data_mod$insitu_and_woa_nutricline[samp], om)
set.seed(123)
rf7 <- randomForest::randomForest(X7, theta, ntree = 500)
A <- sapply(colnames(om), function(k) {
  pd <- sapply(c(0, 1), function(v) { Xv <- X7; Xv[, k] <- v; mean(predict(rf7, Xv)) })
  pd[2] - pd[1]
})

res <- data.frame(stress_type = names(published), published_approx = unname(published),
                  C_main = round(as.numeric(C[names(published)]), 4),
                  C_se = round(as.numeric(Cse[names(published)]), 4),
                  n_dominant = as.integer(table(dom)[names(published)]),
                  A_partial_dependence = round(unname(A[names(published)]), 4),
                  B_resid_omega_pos = round(unname(B[names(published)]), 4),
                  D_raw_by_type = round(as.numeric(D[names(published)]), 4))
cat("\n"); print(res, row.names = FALSE)
for (v in c("C_main", "A_partial_dependence", "B_resid_omega_pos", "D_raw_by_type")) {
  cat(sprintf("%-22s sign agreement %d/6, Pearson r with published %.2f\n", v,
              sum(sign(res[[v]]) == sign(res$published_approx)), cor(res[[v]], res$published_approx)))
}
write.csv(res, file.path(out, "fig1c_results.csv"), row.names = FALSE)

pdf(file.path(out, "fig1c_bars.pdf"), width = 7, height = 4.5)
cols <- c("#1b7a3e", "#1b7a3e", "#3fa9e0", "#3fa9e0", "#f0941f", "#f0941f")
b <- barplot(rbind(res$C_main, res$published_approx), beside = TRUE, col = rbind(cols, adjustcolor(cols, 0.35)),
             names.arg = c("N High", "N Med", "P High", "P Med", "Fe High", "Fe Med"),
             ylab = "Partial Theta' dependence", ylim = c(-0.5, 0.6),
             main = "Fig. 1C reconstruction (solid) vs published, read from figure (pale)")
arrows(b[1, ], res$C_main - res$C_se, b[1, ], res$C_main + res$C_se, angle = 90, code = 3, length = 0.03)
abline(h = 0)
dev.off()

cat("\nSoftware:\n"); print(sessionInfo())
sink()
