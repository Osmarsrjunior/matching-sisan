matching_formula <- stats::as.formula(
  paste(
    "treated ~ log_population_2010 + rural_share_2010 +",
    "extreme_poverty_pct_2010 + income_pc_2010 +",
    "agricultural_employment_pct_2010 + adult_illiteracy_pct_2010 +",
    "public_sector_employment_pct_2010 + idhm_2010 +",
    "pre_2 + pre_1 + pre_trend"
  )
)

mahalanobis_formula <- stats::as.formula(
  paste(
    "~ log_population_2010 + rural_share_2010 +",
    "extreme_poverty_pct_2010 + income_pc_2010 +",
    "agricultural_employment_pct_2010 +",
    "pre_2 + pre_1 + pre_trend"
  )
)

fit_one_cohort_match <- function(risk, cohort, cfg, exact_size = TRUE, ratio = NULL, caliper = NULL) {
  ratio <- ratio %||% cfg$analysis$match_ratio
  caliper <- caliper %||% cfg$analysis$ps_caliper

  risk <- risk |>
    dplyr::mutate(
      uf = factor(.data$uf),
      population_class = factor(.data$population_class)
    )

  exact_formula <- if (exact_size) ~ uf + population_class else ~ uf

  fit <- MatchIt::matchit(
    formula = matching_formula,
    data = risk,
    method = "nearest",
    distance = "glm",
    link = "logit",
    estimand = "ATT",
    mahvars = mahalanobis_formula,
    exact = exact_formula,
    caliper = caliper,
    std.caliper = TRUE,
    ratio = ratio,
    replace = cfg$analysis$match_with_replacement,
    m.order = "closest"
  )

  matched <- MatchIt::match.data(fit, data = risk, drop.unmatched = TRUE) |>
    dplyr::mutate(cohort = as.integer(cohort))

  list(fit = fit, matched = matched, risk = risk)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

fit_all_cohorts <- function(panel, cfg, observed_only = FALSE, exact_size = TRUE,
                            ratio = NULL, caliper = NULL) {
  cohorts <- cfg$analysis$cohorts
  results <- purrr::map(cohorts, function(g) {
    risk <- make_risk_set(panel, g, cfg, observed_only = observed_only)
    fit_one_cohort_match(risk, g, cfg, exact_size = exact_size, ratio = ratio, caliper = caliper)
  })
  names(results) <- as.character(cohorts)
  results
}

stack_matched <- function(matches) {
  purrr::map_dfr(matches, "matched") |>
    dplyr::mutate(
      cohort = factor(.data$cohort),
      treated = as.integer(.data$treated),
      weights = as.numeric(.data$weights)
    )
}

extract_balance <- function(matches) {
  purrr::imap_dfr(matches, function(obj, cohort_name) {
    bal <- cobalt::bal.tab(obj$fit, un = TRUE, binary = "std")$Balance |>
      as.data.frame() |>
      tibble::rownames_to_column("covariate") |>
      dplyr::transmute(
        cohort = as.integer(cohort_name),
        covariate = .data$covariate,
        smd_before = .data$Diff.Un,
        smd_after = .data$Diff.Adj
      )
    bal
  })
}

matching_summary <- function(matches) {
  balance <- extract_balance(matches)
  purrr::imap_dfr(matches, function(obj, cohort_name) {
    sm <- summary(obj$fit)
    tibble::tibble(
      cohort = as.integer(cohort_name),
      treated_available = unname(sm$nn["All", "Treated"]),
      controls_available = unname(sm$nn["All", "Control"]),
      treated_matched = unname(sm$nn["Matched", "Treated"]),
      controls_matched = unname(sm$nn["Matched", "Control"]),
      max_abs_smd_before = max(abs(balance$smd_before[balance$cohort == as.integer(cohort_name)]), na.rm = TRUE),
      max_abs_smd_after = max(abs(balance$smd_after[balance$cohort == as.integer(cohort_name)]), na.rm = TRUE)
    )
  })
}
