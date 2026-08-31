build_municipal_panel <- function(atlas, adoptions, pnae, cfg) {
  years <- cfg$analysis$outcome_years
  minimum_share <- cfg$analysis$minimum_legal_share

  universe <- tidyr::crossing(
    code_muni = atlas$code_muni,
    year = years
  ) |>
    dplyr::left_join(atlas, by = "code_muni") |>
    dplyr::left_join(
      adoptions |>
        dplyr::select("code_muni", "adoption_year"),
      by = "code_muni"
    ) |>
    dplyr::left_join(
      pnae |>
        dplyr::select(
          "code_muni", "year", "value_transferred",
          "value_family_farming", "af_share_observed"
        ),
      by = c("code_muni", "year")
    ) |>
    dplyr::mutate(
      pnae_record_observed = !is.na(.data$af_share_observed),
      # The FNDE extracts enumerate valid recorded family-farming purchases.
      # The primary administrative estimand treats absence from that extract as
      # zero recorded purchase; complete-case estimates are reported separately.
      af_share = dplyr::coalesce(.data$af_share_observed, 0),
      compliant_30 = as.integer(.data$af_share >= minimum_share),
      treated_currently = !is.na(.data$adoption_year) & .data$year >= .data$adoption_year
    )

  assert_unique(universe, c("code_muni", "year"), "Municipal panel")
  universe
}

make_risk_set <- function(panel, cohort, cfg, observed_only = FALSE) {
  pre_years <- cohort - cfg$analysis$pre_lags
  post_years <- cohort + cfg$analysis$post_leads
  last_followup <- max(post_years)

  eligible <- panel |>
    dplyr::distinct(
      code_muni, uf, municipality, adoption_year,
      population_2010, population_class, log_population_2010,
      rural_share_2010, extreme_poverty_pct_2010,
      vulnerable_poverty_pct_2010, income_pc_2010,
      agricultural_employment_pct_2010, adult_illiteracy_pct_2010,
      public_sector_employment_pct_2010, idhm_2010
    ) |>
    dplyr::mutate(
      treated = as.integer(!is.na(.data$adoption_year) & .data$adoption_year == cohort),
      eligible_control = is.na(.data$adoption_year) | .data$adoption_year > last_followup
    ) |>
    dplyr::filter(.data$treated == 1L | .data$eligible_control)

  outcomes <- panel |>
    dplyr::filter(.data$year %in% c(pre_years, post_years)) |>
    dplyr::mutate(relative_year = .data$year - cohort) |>
    dplyr::select(
      "code_muni", "relative_year", "af_share",
      "af_share_observed", "compliant_30", "pnae_record_observed"
    ) |>
    tidyr::pivot_wider(
      names_from = "relative_year",
      values_from = c("af_share", "af_share_observed", "compliant_30", "pnae_record_observed"),
      names_glue = "{.value}_t{relative_year}"
    )

  risk <- eligible |>
    dplyr::left_join(outcomes, by = "code_muni") |>
    dplyr::mutate(
      cohort = as.integer(cohort),
      pre_2 = .data[["af_share_t-2"]],
      pre_1 = .data[["af_share_t-1"]],
      pre_average = rowMeans(cbind(.data$pre_2, .data$pre_1), na.rm = FALSE),
      pre_trend = .data$pre_1 - .data$pre_2,
      post_average = rowMeans(cbind(.data$af_share_t1, .data$af_share_t2, .data$af_share_t3), na.rm = FALSE),
      post_compliance = rowMeans(cbind(.data$compliant_30_t1, .data$compliant_30_t2, .data$compliant_30_t3), na.rm = FALSE),
      observed_all_pre = .data[["pnae_record_observed_t-2"]] & .data[["pnae_record_observed_t-1"]],
      observed_all_post = .data$pnae_record_observed_t1 & .data$pnae_record_observed_t2 & .data$pnae_record_observed_t3
    )

  if (observed_only) {
    risk <- risk |>
      dplyr::filter(.data$observed_all_pre, .data$observed_all_post) |>
      dplyr::mutate(
        pre_2 = .data[["af_share_observed_t-2"]],
        pre_1 = .data[["af_share_observed_t-1"]],
        pre_average = rowMeans(cbind(.data$pre_2, .data$pre_1), na.rm = FALSE),
        pre_trend = .data$pre_1 - .data$pre_2,
        post_average = rowMeans(
          cbind(.data$af_share_observed_t1, .data$af_share_observed_t2, .data$af_share_observed_t3),
          na.rm = FALSE
        )
      )
  }

  risk |>
    dplyr::filter(
      is.finite(.data$pre_2), is.finite(.data$pre_1),
      is.finite(.data$post_average), is.finite(.data$post_compliance)
    )
}
