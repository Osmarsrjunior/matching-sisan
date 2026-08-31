tidy_fixest_term <- function(model, term = "treated") {
  broom::tidy(model, conf.int = TRUE) |>
    dplyr::filter(.data$term == .env$term) |>
    dplyr::select("estimate", "std.error", "conf.low", "conf.high", "p.value")
}

estimate_att <- function(matched, outcome = c("post_average", "post_compliance"), adjusted = TRUE) {
  outcome <- match.arg(outcome)
  rhs <- if (adjusted) "treated + pre_average + pre_trend" else "treated"
  fml <- stats::as.formula(paste0(outcome, " ~ ", rhs, " | cohort"))

  model <- fixest::feols(
    fml,
    data = matched,
    weights = ~ weights,
    cluster = ~ code_muni,
    warn = FALSE,
    notes = FALSE
  )

  tidy_fixest_term(model) |>
    dplyr::mutate(
      outcome = outcome,
      adjusted = adjusted,
      n_rows = stats::nobs(model),
      n_municipalities = dplyr::n_distinct(matched$code_muni)
    ) |>
    dplyr::relocate("outcome", "adjusted")
}

estimate_main_effects <- function(matched) {
  purrr::map_dfr(
    list(
      c("post_average", FALSE),
      c("post_average", TRUE),
      c("post_compliance", FALSE),
      c("post_compliance", TRUE)
    ),
    ~ estimate_att(matched, outcome = .x[[1]], adjusted = as.logical(.x[[2]]))
  ) |>
    dplyr::mutate(
      estimate_display = dplyr::if_else(
        .data$outcome == "post_compliance",
        100 * .data$estimate,
        .data$estimate
      ),
      conf_low_display = dplyr::if_else(
        .data$outcome == "post_compliance",
        100 * .data$conf.low,
        .data$conf.low
      ),
      conf_high_display = dplyr::if_else(
        .data$outcome == "post_compliance",
        100 * .data$conf.high,
        .data$conf.high
      )
    )
}

build_matched_event_panel <- function(panel, matches, cfg, observed_only = FALSE) {
  purrr::imap_dfr(matches, function(obj, cohort_name) {
    g <- as.integer(cohort_name)
    keys <- obj$matched |>
      dplyr::select("code_muni", "treated", "weights")

    panel |>
      dplyr::filter(.data$year >= g - 2L, .data$year <= g + 3L) |>
      dplyr::inner_join(keys, by = "code_muni") |>
      dplyr::mutate(
        cohort = factor(g),
        relative_year = .data$year - g,
        outcome_event = if (observed_only) .data$af_share_observed else .data$af_share
      ) |>
      dplyr::filter(is.finite(.data$outcome_event))
  })
}

estimate_event_effects <- function(event_panel) {
  purrr::map_dfr(sort(unique(event_panel$relative_year)), function(k) {
    dat <- dplyr::filter(event_panel, .data$relative_year == k)
    fit <- fixest::feols(
      outcome_event ~ treated | cohort,
      data = dat,
      weights = ~ weights,
      cluster = ~ code_muni,
      warn = FALSE,
      notes = FALSE
    )
    tidy_fixest_term(fit) |>
      dplyr::mutate(relative_year = k, n_rows = stats::nobs(fit))
  }) |>
    dplyr::relocate("relative_year")
}

weighting_formula <- stats::as.formula(
  paste(
    "treated ~ factor(uf) + factor(population_class) +",
    "log_population_2010 + rural_share_2010 +",
    "extreme_poverty_pct_2010 + income_pc_2010 +",
    "agricultural_employment_pct_2010 + adult_illiteracy_pct_2010 +",
    "public_sector_employment_pct_2010 + idhm_2010 +",
    "pre_2 + pre_1 + pre_trend"
  )
)

fit_entropy_balancing <- function(panel, cfg) {
  purrr::map_dfr(cfg$analysis$cohorts, function(g) {
    risk <- make_risk_set(panel, g, cfg) |>
      dplyr::mutate(
        uf = factor(.data$uf),
        population_class = factor(.data$population_class)
      )
    fit <- WeightIt::weightit(
      weighting_formula,
      data = risk,
      method = "ebal",
      estimand = "ATT"
    )
    risk |>
      dplyr::mutate(
        weights = as.numeric(fit$weights),
        cohort = factor(g)
      ) |>
      dplyr::filter(is.finite(.data$weights), .data$weights > 0)
  })
}

fit_cem <- function(panel, cfg) {
  cem_formula <- treated ~ uf + population_class + pre_average + pre_trend +
    extreme_poverty_pct_2010 + agricultural_employment_pct_2010

  purrr::map_dfr(cfg$analysis$cohorts, function(g) {
    risk <- make_risk_set(panel, g, cfg) |>
      dplyr::mutate(
        uf = factor(.data$uf),
        population_class = factor(.data$population_class)
      )
    fit <- MatchIt::matchit(
      cem_formula,
      data = risk,
      method = "cem",
      estimand = "ATT",
      cutpoints = list(
        pre_average = 5L,
        pre_trend = 5L,
        extreme_poverty_pct_2010 = 4L,
        agricultural_employment_pct_2010 = 4L
      )
    )
    MatchIt::match.data(fit, data = risk, drop.unmatched = TRUE) |>
      dplyr::mutate(cohort = factor(g), weights = as.numeric(.data$weights))
  })
}

run_robustness <- function(panel, cfg) {
  specs <- list(
    main = list(observed_only = FALSE, exact_size = TRUE, ratio = 1L, caliper = 0.20),
    complete_case = list(observed_only = TRUE, exact_size = TRUE, ratio = 1L, caliper = 0.20),
    caliper_010 = list(observed_only = FALSE, exact_size = TRUE, ratio = 1L, caliper = 0.10),
    caliper_030 = list(observed_only = FALSE, exact_size = TRUE, ratio = 1L, caliper = 0.30),
    exact_state_only = list(observed_only = FALSE, exact_size = FALSE, ratio = 1L, caliper = 0.20),
    three_controls = list(observed_only = FALSE, exact_size = TRUE, ratio = 3L, caliper = 0.20)
  )

  matching_specs <- purrr::imap_dfr(specs, function(s, spec_name) {
    matches <- fit_all_cohorts(
      panel, cfg,
      observed_only = s$observed_only,
      exact_size = s$exact_size,
      ratio = s$ratio,
      caliper = s$caliper
    )
    matched <- stack_matched(matches)
    estimate_att(matched, outcome = "post_average", adjusted = TRUE) |>
      dplyr::mutate(specification = spec_name, .before = 1L)
  })

  entropy <- fit_entropy_balancing(panel, cfg) |>
    estimate_att(outcome = "post_average", adjusted = TRUE) |>
    dplyr::mutate(specification = "entropy_balancing", .before = 1L)

  cem <- fit_cem(panel, cfg) |>
    estimate_att(outcome = "post_average", adjusted = TRUE) |>
    dplyr::mutate(specification = "cem", .before = 1L)

  dplyr::bind_rows(matching_specs, entropy, cem)
}
