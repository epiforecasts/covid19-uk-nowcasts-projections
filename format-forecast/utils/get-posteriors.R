# load convolution posteriors with sd scaling for a given data and targe
get_posteriors <- function(date, target, type = "snapshot", scale_sd = 1) {
  type <- match.arg(type, choices = c("snapshot", "all"))
  safe_fread <- purrr::safely(fread)
  posteriors <- safe_fread(
    here(
      "format-forecast", "posteriors", type, target,
      paste0(date, ".csv")
    )
  )[[1]]

  if (!is.null(posteriors)) {
    posteriors <- posteriors[, sd := sd * scale_sd]
  }
  return(posteriors)
}
