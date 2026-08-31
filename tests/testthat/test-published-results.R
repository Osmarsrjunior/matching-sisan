testthat::test_that("published main estimates match the pipeline output", {
  effects <- readr::read_csv(
    file.path(project_root, "outputs", "tables", "table_06_main_effects.csv"),
    show_col_types = FALSE
  )
  main <- effects |>
    dplyr::filter(.data$outcome == "post_average", .data$adjusted)
  compliance <- effects |>
    dplyr::filter(.data$outcome == "post_compliance", .data$adjusted)

  testthat::expect_equal(main$estimate, 3.0909515362, tolerance = 1e-8)
  testthat::expect_equal(main$n_rows, 476)
  testthat::expect_equal(compliance$estimate_display, 3.8955708518, tolerance = 1e-8)
})

testthat::test_that("all four eligible cohorts appear in the matching table", {
  x <- readr::read_csv(
    file.path(project_root, "outputs", "tables", "table_03_matching_by_cohort.csv"),
    show_col_types = FALSE
  )
  testthat::expect_equal(x$cohort, 2016:2019)
  testthat::expect_equal(sum(x$treated_matched), 238)
})
