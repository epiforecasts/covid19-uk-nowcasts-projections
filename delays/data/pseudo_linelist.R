
# Packages ----------------------------------------------------------------

require(dplyr)
require(tibble)
require(lubridate)

# Report delay ------------------------------------------------------------

report_delay <- readRDS(here::here("delays/data/delay.rds"))

# Construct pseudo linelist -----------------------------------------------

pseudo_linelist <- tibble::tibble(
  report_delay = report_delay
) %>%
  dplyr::mutate(
    date_confirm = readRDS(here::here("data", "forecast_date.rds")) -
      lubridate::days(10),
    date_onset = date_confirm - lubridate::days(report_delay),
    import_status = "local"
  ) %>%
  dplyr::select(date_confirm, date_onset, report_delay, import_status)

# Save peudo_linelist -----------------------------------------------------

saveRDS(pseudo_linelist, "delays/data/pseudo_linelist.rds")
