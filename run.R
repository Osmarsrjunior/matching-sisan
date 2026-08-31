#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, scipen = 999)
set.seed(20260828)

required <- c(
  "broom", "cobalt", "dplyr", "fixest", "ggplot2", "here",
  "MatchIt", "purrr", "readr", "readxl", "scales", "stringi", "stringr",
  "tibble", "tidyr", "WeightIt", "yaml"
)
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install missing packages before running: ", paste(missing, collapse = ", "))
}

source("R/config.R")
source("R/utils.R")
source("R/import_treatment.R")
source("R/import_pnae.R")
source("R/build_panel.R")
source("R/match_cohorts.R")
source("R/estimate.R")
source("R/report.R")

cfg <- read_config()
ensure_output_dirs(cfg)

message("1/7 Importing archived treatment and covariates...")
adoptions <- read_sisan_adoptions()
atlas <- read_atlas_covariates()

message("2/7 Importing FNDE/PNAE workbooks...")
pnae <- read_pnae_panel(cfg)

message("3/7 Building municipal panel...")
panel <- build_municipal_panel(atlas, adoptions, pnae, cfg)
readr::write_csv(panel, file.path(cfg$paths$processed, "municipal_panel.csv"), na = "")

message("4/7 Matching annual adoption cohorts...")
matches <- fit_all_cohorts(panel, cfg)
matched <- stack_matched(matches)
balance <- extract_balance(matches)
match_summary <- matching_summary(matches)

message("5/7 Estimating effects and sensitivity specifications...")
effects <- estimate_main_effects(matched)
event_panel <- build_matched_event_panel(panel, matches, cfg)
event_effects <- estimate_event_effects(event_panel)
robustness <- run_robustness(panel, cfg)

message("6/7 Writing tables and figures...")
write_analysis_outputs(
  adoptions = adoptions,
  panel = panel,
  matched = matched,
  balance = balance,
  match_summary = match_summary,
  effects = effects,
  event_effects = event_effects,
  robustness = robustness,
  cfg = cfg
)

message("7/7 Running assertions...")
stopifnot(nrow(panel) == 5565L * length(cfg$analysis$outcome_years))
stopifnot(all(abs(balance$smd_after) < 1 | is.na(balance$smd_after)))
stopifnot(nrow(event_effects) == 6L)
message("Done. Results are in outputs/ and data/processed/.")
