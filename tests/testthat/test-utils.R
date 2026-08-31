testthat::test_that("parse_number_br handles Brazilian and textual percentages", {
  x <- c("1.234,56", "27,5%", "100% ou mais", "-")
  testthat::expect_equal(parse_number_br(x), c(1234.56, 27.5, 100, NA_real_))
})

testthat::test_that("municipal codes are standardized to seven digits", {
  testthat::expect_equal(format_code_muni(c("110001", "1100015")), c("1100010", "1100015"))
})

testthat::test_that("size classes use the documented cutoffs", {
  out <- as.character(size_class(c(20000, 20001, 50000, 50001, 500001)))
  testthat::expect_equal(
    out,
    c("ate_20_mil", "20_a_50_mil", "20_a_50_mil", "50_a_100_mil", "mais_500_mil")
  )
})
