testthat::test_that("the archived SISAN treatment file has unique municipalities", {
  x <- read_sisan_adoptions(file.path(project_root, "data-raw", "sisan_adoptions.csv"))
  testthat::expect_equal(nrow(x), 2467L)
  testthat::expect_equal(dplyr::n_distinct(x$code_muni), 2467L)
  testthat::expect_equal(sum(x$adoption_year %in% 2016:2019), 271L)
})

testthat::test_that("the Atlas file defines the expected municipal universe", {
  x <- read_atlas_covariates(file.path(project_root, "data-raw", "atlas_2010_covariates.csv"))
  testthat::expect_equal(nrow(x), 5565L)
  testthat::expect_false(anyDuplicated(x$code_muni) > 0L)
})
