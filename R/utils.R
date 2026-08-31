clean_text <- function(x) {
  x |>
    as.character() |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("[^a-z0-9]+", "_") |>
    stringr::str_replace_all("^_|_$", "")
}

clean_names_local <- function(df) {
  names(df) <- make.unique(clean_text(names(df)), sep = "_")
  df
}

parse_number_br <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  value <- stringr::str_trim(as.character(x))
  value[value %in% c("", "NA", "N/A", "-", "null")] <- NA_character_
  textual_hundred <- clean_text(value) == "100_ou_mais"
  textual_hundred[is.na(textual_hundred)] <- FALSE
  value[textual_hundred] <- "100"
  value <- stringr::str_replace_all(value, "%", "")

  both_marks <- stringr::str_detect(value, ",") & stringr::str_detect(value, stringr::fixed("."))
  comma_only <- stringr::str_detect(value, ",") & !stringr::str_detect(value, stringr::fixed("."))
  both_marks[is.na(both_marks)] <- FALSE
  comma_only[is.na(comma_only)] <- FALSE
  value[both_marks] <- value[both_marks] |>
    stringr::str_replace_all(stringr::fixed("."), "") |>
    stringr::str_replace_all(",", ".")
  value[comma_only] <- stringr::str_replace_all(value[comma_only], ",", ".")
  suppressWarnings(as.numeric(value))
}

first_col_matching <- function(nms, pattern, exclude = NULL) {
  idx <- stringr::str_which(nms, pattern)
  if (!is.null(exclude)) idx <- idx[!stringr::str_detect(nms[idx], exclude)]
  if (!length(idx)) return(NA_character_)
  nms[idx[1]]
}

format_code_muni <- function(x) {
  digits <- stringr::str_extract(as.character(x), "[0-9]{6,7}")
  digits <- ifelse(nchar(digits) == 6, paste0(digits, "0"), digits)
  stringr::str_pad(digits, width = 7, side = "left", pad = "0")
}

weighted_mean_safe <- function(x, w) {
  ok <- is.finite(x) & is.finite(w) & w > 0
  if (!any(ok)) return(NA_real_)
  stats::weighted.mean(x[ok], w[ok])
}

size_class <- function(population) {
  cut(
    population,
    breaks = c(-Inf, 20000, 50000, 100000, 500000, Inf),
    labels = c("ate_20_mil", "20_a_50_mil", "50_a_100_mil", "100_a_500_mil", "mais_500_mil"),
    right = TRUE,
    ordered_result = TRUE
  )
}

assert_unique <- function(df, keys, label = deparse(substitute(df))) {
  n_dup <- df |>
    dplyr::count(dplyr::across(dplyr::all_of(keys))) |>
    dplyr::filter(.data$n > 1L) |>
    nrow()
  if (n_dup > 0L) stop(label, " contains duplicated keys: ", paste(keys, collapse = ", "))
  invisible(df)
}
