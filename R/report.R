theme_article <- function() {
  ggplot2::theme_minimal(base_family = "DejaVu Sans", base_size = 10.5) +
    ggplot2::theme(
      plot.title.position = "plot",
      plot.title = ggplot2::element_text(face = "bold", size = 12),
      plot.subtitle = ggplot2::element_text(color = "grey35", size = 9.5),
      plot.caption = ggplot2::element_text(color = "grey45", hjust = 0, size = 8),
      panel.grid.minor = ggplot2::element_blank(),
      axis.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )
}

pretty_covariate <- function(x) {
  labels <- c(
    distance = "Escore de propensão",
    log_population_2010 = "Log da população (2010)",
    rural_share_2010 = "População rural (%)",
    extreme_poverty_pct_2010 = "Extrema pobreza (%)",
    income_pc_2010 = "Renda per capita",
    agricultural_employment_pct_2010 = "Ocupação agropecuária (%)",
    adult_illiteracy_pct_2010 = "Analfabetismo adulto (%)",
    public_sector_employment_pct_2010 = "Ocupação no setor público (%)",
    idhm_2010 = "IDHM",
    pre_2 = "PNAE: t - 2",
    pre_1 = "PNAE: t - 1",
    pre_trend = "Tendência prévia do PNAE"
  )
  out <- unname(labels[x])
  out[is.na(out)] <- x[is.na(out)]
  out
}

write_analysis_outputs <- function(adoptions, panel, matched, balance, match_summary,
                                   effects, event_effects, robustness, cfg) {
  table_dir <- cfg$paths$tables
  figure_dir <- cfg$paths$figures

  adoption_counts <- adoptions |>
    dplyr::count(.data$adoption_year, name = "new_adoptions") |>
    dplyr::arrange(.data$adoption_year) |>
    dplyr::mutate(cumulative_adoptions = cumsum(.data$new_adoptions))

  coverage <- panel |>
    dplyr::group_by(.data$year) |>
    dplyr::summarise(
      municipalities = dplyr::n(),
      records_observed = sum(.data$pnae_record_observed),
      records_absent_coded_zero = sum(!.data$pnae_record_observed),
      observed_share_pct = 100 * mean(.data$pnae_record_observed),
      mean_af_share_primary = mean(.data$af_share),
      mean_af_share_observed = mean(.data$af_share_observed, na.rm = TRUE),
      .groups = "drop"
    )

  matched_descriptives <- matched |>
    dplyr::group_by(.data$treated) |>
    dplyr::summarise(
      rows = dplyr::n(),
      unique_municipalities = dplyr::n_distinct(.data$code_muni),
      pre_mean = weighted_mean_safe(.data$pre_average, .data$weights),
      post_mean = weighted_mean_safe(.data$post_average, .data$weights),
      post_compliance_pct = 100 * weighted_mean_safe(.data$post_compliance, .data$weights),
      .groups = "drop"
    ) |>
    dplyr::mutate(group = dplyr::if_else(.data$treated == 1L, "Aderentes", "Controles pareados")) |>
    dplyr::select("group", dplyr::everything(), -"treated")

  balance_average <- balance |>
    dplyr::filter(
      .data$covariate != "distance",
      !stringr::str_detect(.data$covariate, "^(uf_|population_class_)")
    ) |>
    dplyr::group_by(.data$covariate) |>
    dplyr::summarise(
      mean_abs_smd_before = mean(abs(.data$smd_before), na.rm = TRUE),
      mean_abs_smd_after = mean(abs(.data$smd_after), na.rm = TRUE),
      max_abs_smd_after = max(abs(.data$smd_after), na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(label = pretty_covariate(.data$covariate))

  readr::write_csv(adoption_counts, file.path(table_dir, "table_01_sisan_adoptions_by_year.csv"))
  readr::write_csv(coverage, file.path(table_dir, "table_02_pnae_data_coverage.csv"))
  readr::write_csv(match_summary, file.path(table_dir, "table_03_matching_by_cohort.csv"))
  readr::write_csv(balance_average, file.path(table_dir, "table_04_covariate_balance.csv"))
  readr::write_csv(matched_descriptives, file.path(table_dir, "table_05_matched_descriptives.csv"))
  readr::write_csv(effects, file.path(table_dir, "table_06_main_effects.csv"))
  readr::write_csv(event_effects, file.path(table_dir, "table_07_event_time_effects.csv"))
  readr::write_csv(robustness, file.path(table_dir, "table_08_robustness.csv"))
  readr::write_csv(matched, file.path(cfg$paths$processed, "matched_cohort_sample.csv"), na = "")

  p_adoption <- ggplot2::ggplot(adoption_counts, ggplot2::aes(.data$adoption_year, .data$cumulative_adoptions)) +
    ggplot2::geom_area(fill = "#C9D9E8", alpha = 0.9) +
    ggplot2::geom_line(color = "#1F4E79", linewidth = 0.9) +
    ggplot2::geom_point(color = "#1F4E79", size = 1.8) +
    ggplot2::scale_x_continuous(breaks = adoption_counts$adoption_year) +
    ggplot2::scale_y_continuous(
      labels = scales::label_number(big.mark = ".", decimal.mark = ","),
      expand = ggplot2::expansion(mult = c(0, 0.05))
    ) +
    ggplot2::labs(
      title = "A adesão municipal ao SISAN acelerou após 2023",
      subtitle = "A avaliação causal usa apenas coortes com três anos de resultados observáveis (2016–2019)",
      x = "Ano da resolução de adesão", y = "Municípios aderentes (acumulado)",
      caption = "Fonte: lista oficial do MDS, atualização de 26 ago. 2026."
    ) +
    theme_article()

  balance_long <- balance_average |>
    dplyr::select("label", "mean_abs_smd_before", "mean_abs_smd_after") |>
    tidyr::pivot_longer(-"label", names_to = "sample", values_to = "mean_abs_smd") |>
    dplyr::mutate(
      sample = dplyr::recode(.data$sample,
        mean_abs_smd_before = "Antes do pareamento",
        mean_abs_smd_after = "Depois do pareamento"
      ),
      label = stats::reorder(.data$label, .data$mean_abs_smd)
    )

  p_balance <- ggplot2::ggplot(balance_long, ggplot2::aes(.data$mean_abs_smd, .data$label, color = .data$sample)) +
    ggplot2::geom_vline(xintercept = 0.10, linetype = "dashed", color = "grey50") +
    ggplot2::geom_point(size = 2.4) +
    ggplot2::scale_color_manual(values = c("Antes do pareamento" = "#B14A3B", "Depois do pareamento" = "#1F6F5F")) +
    ggplot2::labs(
      title = "O matching reduziu as diferenças observáveis entre os grupos",
      subtitle = "Média, entre coortes, do valor absoluto da diferença padronizada de médias",
      x = "|Diferença padronizada de médias|", y = NULL, color = NULL,
      caption = "A linha tracejada marca o limiar convencional de 0,10."
    ) +
    theme_article()

  p_event <- ggplot2::ggplot(event_effects, ggplot2::aes(.data$relative_year, .data$estimate)) +
    ggplot2::geom_hline(yintercept = 0, color = "grey45") +
    ggplot2::geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey55") +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$conf.low, ymax = .data$conf.high), fill = "#B8CDE0", alpha = 0.7) +
    ggplot2::geom_line(color = "#1F4E79", linewidth = 0.9) +
    ggplot2::geom_point(color = "#1F4E79", size = 2.2) +
    ggplot2::scale_x_continuous(breaks = -2:3) +
    ggplot2::labs(
      title = "Diferenças pareadas antes e depois da adesão",
      subtitle = "Efeito em pontos percentuais do PNAE destinados à agricultura familiar; IC de 95%",
      x = "Anos em relação à adesão", y = "Diferença aderente – controle (p.p.)",
      caption = "O ano 0 é mostrado descritivamente; o estimando principal usa os anos +1 a +3."
    ) +
    theme_article()

  robustness_plot <- robustness |>
    dplyr::mutate(
      label = dplyr::recode(.data$specification,
        main = "Principal",
        complete_case = "Somente registros observados",
        caliper_010 = "Caliper 0,10",
        caliper_030 = "Caliper 0,30",
        exact_state_only = "Exato apenas por UF",
        three_controls = "Três controles",
        entropy_balancing = "Balanceamento por entropia",
        cem = "Coarsened exact matching (CEM)"
      ),
      label = factor(.data$label, levels = rev(c(
        "Principal", "Somente registros observados", "Caliper 0,10",
        "Caliper 0,30", "Exato apenas por UF", "Três controles",
        "Balanceamento por entropia", "Coarsened exact matching (CEM)"
      )))
    )

  p_robust <- ggplot2::ggplot(robustness_plot, ggplot2::aes(.data$estimate, .data$label)) +
    ggplot2::geom_vline(xintercept = 0, color = "grey50") +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = .data$conf.low, xmax = .data$conf.high),
      orientation = "y", width = 0.16, color = "#446A82"
    ) +
    ggplot2::geom_point(color = "#1F4E79", size = 2.3) +
    ggplot2::labs(
      title = "Sensibilidade do efeito médio pós-adesão",
      subtitle = "Estimativas ajustadas; pontos percentuais e intervalos de confiança de 95%",
      x = "Efeito sobre a participação da agricultura familiar (p.p.)", y = NULL,
      caption = "Erros-padrão agrupados por município."
    ) +
    theme_article()

  ggplot2::ggsave(file.path(figure_dir, "figure_01_adoption_timeline.png"), p_adoption, width = 7.2, height = 4.2, dpi = 320, bg = "white")
  ggplot2::ggsave(file.path(figure_dir, "figure_02_balance.png"), p_balance, width = 7.2, height = 4.8, dpi = 320, bg = "white")
  ggplot2::ggsave(file.path(figure_dir, "figure_03_event_effects.png"), p_event, width = 7.2, height = 4.5, dpi = 320, bg = "white")
  ggplot2::ggsave(file.path(figure_dir, "figure_04_robustness.png"), p_robust, width = 7.2, height = 4.5, dpi = 320, bg = "white")

  invisible(list(
    adoption_counts = adoption_counts,
    coverage = coverage,
    matched_descriptives = matched_descriptives,
    balance_average = balance_average
  ))
}
