find_header_row <- function(path, sheet = 1L, max_rows = 20L) {
  preview <- readxl::read_excel(
    path, sheet = sheet, col_names = FALSE, n_max = max_rows,
    .name_repair = "unique_quiet"
  )
  hits <- apply(preview, 1L, function(row) {
    txt <- clean_text(paste(row, collapse = " "))
    stringr::str_detect(txt, "percentual|percentual_de_aquisicao") &&
      stringr::str_detect(txt, "entidade|municipio")
  })
  idx <- which(hits)[1]
  if (is.na(idx)) stop("Could not identify header row in ", path)
  idx
}

read_one_pnae <- function(path, year) {
  header_row <- find_header_row(path)
  # Read as text to preserve entries such as "100% ou mais" that otherwise
  # become missing when readxl guesses a numeric column type.
  raw <- readxl::read_excel(
    path,
    sheet = 1L,
    skip = header_row - 1L,
    col_types = "text",
    .name_repair = "unique_quiet"
  ) |>
    clean_names_local()
  nms <- names(raw)

  code_col <- first_col_matching(nms, "ibge")
  uf_col <- first_col_matching(nms, "^uf$")
  entity_col <- first_col_matching(nms, "entidade")
  transfer_col <- first_col_matching(nms, "trans?fer|creditado")
  share_col <- first_col_matching(nms, "percent")
  af_value_col <- first_col_matching(nms, "valor.*aqu|aqu.*agricultura", exclude = "percent")
  sphere_col <- first_col_matching(nms, "esfera")

  if (anyNA(c(code_col, uf_col, entity_col, transfer_col, share_col, af_value_col))) {
    stop("Required columns were not identified in ", basename(path), ". Names: ", paste(nms, collapse = ", "))
  }

  out <- tibble::tibble(
    year = as.integer(year),
    code_muni = format_code_muni(raw[[code_col]]),
    uf = stringr::str_to_upper(as.character(raw[[uf_col]])),
    entity = as.character(raw[[entity_col]]),
    value_transferred = parse_number_br(raw[[transfer_col]]),
    value_family_farming = parse_number_br(raw[[af_value_col]]),
    published_share = parse_number_br(raw[[share_col]]),
    sphere = if (is.na(sphere_col)) NA_character_ else stringr::str_to_upper(as.character(raw[[sphere_col]]))
  )

  if (year %in% c(2014:2017, 2020:2022)) {
    out$published_share <- 100 * out$published_share
  }

  municipal_name <- stringr::str_detect(
    clean_text(out$entity),
    "(^|_)(pref|prefeitura|municipio|municipal|pm|sec_mun)(_|$)"
  )
  municipal_sphere <- is.na(out$sphere) | out$sphere == "MUNICIPAL"

  out |>
    dplyr::filter(
      !is.na(.data$code_muni),
      stringr::str_detect(.data$code_muni, "^[0-9]{7}$"),
      municipal_name,
      municipal_sphere
    ) |>
    dplyr::mutate(
      share_from_values = dplyr::if_else(
        .data$value_transferred > 0,
        100 * .data$value_family_farming / .data$value_transferred,
        NA_real_
      ),
      af_share_raw = dplyr::coalesce(.data$published_share, .data$share_from_values),
      share_was_capped = .data$af_share_raw > 100,
      # Percentages above 100 can reflect own-resource purchases or data-entry
      # anomalies. The bounded implementation outcome is capped at 100.
      af_share_observed = pmin(pmax(.data$af_share_raw, 0), 100)
    ) |>
    dplyr::group_by(.data$code_muni, .data$year) |>
    dplyr::summarise(
      uf = dplyr::first(.data$uf),
      entity = dplyr::first(.data$entity),
      value_transferred = sum(.data$value_transferred, na.rm = TRUE),
      value_family_farming = sum(.data$value_family_farming, na.rm = TRUE),
      share_was_capped = any(.data$share_was_capped, na.rm = TRUE),
      af_share_observed = weighted_mean_safe(
        .data$af_share_observed,
        dplyr::if_else(.data$value_transferred > 0, .data$value_transferred, 1)
      ),
      .groups = "drop"
    )
}

read_pnae_panel <- function(cfg) {
  years <- cfg$analysis$outcome_years
  paths <- file.path(cfg$paths$raw, "fnde", paste0("pnae_af_", years, ifelse(years == 2017L, ".xls", ".xlsx")))
  missing_files <- paths[!file.exists(paths)]
  if (length(missing_files)) stop("Missing raw PNAE files: ", paste(missing_files, collapse = ", "))

  purrr::map2_dfr(paths, years, read_one_pnae) |>
    dplyr::arrange(.data$code_muni, .data$year)
}
