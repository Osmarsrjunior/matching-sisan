read_sisan_adoptions <- function(path = "data-raw/sisan_adoptions.csv") {
  adoptions <- readr::read_csv(
    path,
    col_types = readr::cols(
      code_muni = readr::col_character(),
      uf = readr::col_character(),
      municipality = readr::col_character(),
      adoption_year = readr::col_integer(),
      resolution = readr::col_character()
    ),
    show_col_types = FALSE
  ) |>
    dplyr::mutate(code_muni = format_code_muni(.data$code_muni)) |>
    dplyr::arrange(.data$adoption_year, .data$uf, .data$municipality)

  stopifnot(nrow(adoptions) == 2467L)
  stopifnot(all(adoptions$adoption_year >= 2013L & adoptions$adoption_year <= 2026L))
  assert_unique(adoptions, "code_muni", "SISAN adoption archive")
  adoptions
}

read_atlas_covariates <- function(path = "data-raw/atlas_2010_covariates.csv") {
  atlas <- readr::read_csv(
    path,
    col_types = readr::cols(code_muni = readr::col_character(), .default = readr::col_guess()),
    show_col_types = FALSE
  ) |>
    dplyr::mutate(
      code_muni = format_code_muni(.data$code_muni),
      log_population_2010 = log(.data$population_2010),
      population_class = size_class(.data$population_2010)
    )

  stopifnot(nrow(atlas) == 5565L)
  assert_unique(atlas, "code_muni", "Atlas covariates")
  atlas
}

