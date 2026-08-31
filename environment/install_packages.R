required <- c(
  "broom", "cobalt", "dplyr", "fixest", "ggplot2", "here",
  "MatchIt", "purrr", "readr", "readxl", "scales", "stringi", "stringr",
  "tibble", "tidyr", "WeightIt", "yaml", "testthat"
)

missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  install.packages(missing, repos = "https://cloud.r-project.org")
} else {
  message("Todos os pacotes necessários já estão instalados.")
}
