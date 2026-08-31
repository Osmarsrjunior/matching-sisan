read_config <- function(path = "config.yml") {
  cfg <- yaml::read_yaml(path)

  cfg$analysis$outcome_years <- as.integer(unlist(cfg$analysis$outcome_years))
  cfg$analysis$cohorts <- as.integer(unlist(cfg$analysis$cohorts))
  cfg$analysis$pre_lags <- as.integer(unlist(cfg$analysis$pre_lags))
  cfg$analysis$post_leads <- as.integer(unlist(cfg$analysis$post_leads))
  cfg$analysis$match_ratio <- as.integer(cfg$analysis$match_ratio)
  cfg$analysis$ps_caliper <- as.numeric(cfg$analysis$ps_caliper)
  cfg$analysis$match_with_replacement <- isTRUE(cfg$analysis$match_with_replacement)
  cfg$analysis$minimum_legal_share <- as.numeric(cfg$analysis$minimum_legal_share)
  cfg
}

ensure_output_dirs <- function(cfg) {
  dirs <- unlist(cfg$paths[c("processed", "tables", "figures")])
  invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))
}
