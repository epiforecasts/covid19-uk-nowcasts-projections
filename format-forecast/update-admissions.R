# Packages ----------------------------------------------------------------
require(EpiNow2, quietly = TRUE)
suppressMessages(require(here, quietly = TRUE))
require(stringr, quietly = TRUE)
suppressMessages(require(dplyr, quietly = TRUE))
suppressMessages(require(purrr, quietly = TRUE))
require(ggplot2, quietly = TRUE)
suppressMessages(library(data.table, quietly = TRUE))

# Control parameters ------------------------------------------------------
forecast_date <- readRDS(here::here("data", "forecast_date.rds"))
## Assumes forecasts are in national and regional subfolders

# Load forecasts ----------------------------------------------------------
forecasts <- get_regional_results(
  results_dir = here::here("forecast", "admissions", "regional"),
  date = forecast_date, forecast = TRUE,
  samples = TRUE
)$estimated_reported_cases$samples
forecasts <-
  forecasts[!region %in% c("United Kingdom", "England")][type == "gp_rt"][
  ,
  type := NULL
]

# Format forecasts --------------------------------------------------------
source(here::here("format-forecast/utils/format-forecast.R"))
formatted_forecasts <- format_forecast(forecasts,
  forecast_value = "hospital_inc",
  version = "2.0", forecast_date = forecast_date,
  shrink_per = 0,
  model_type = "Cases",
  scenario = "MTP"
)

formatted_forecasts <- formatted_forecasts[!Geography %in% "England"]
england <- data.table::copy(formatted_forecasts)[
  !Geography %in% c("Scotland", "Wales", "Northern Ireland"),
  lapply(.SD, sum, na.rm = TRUE),
  by = setdiff(colnames(formatted_forecasts), c("Geography", "Value",
               grep("Quantile", colnames(formatted_forecasts), value = TRUE))),
  .SDcols = c("Value",
              eval(grep("Quantile", colnames(formatted_forecasts),
                   value = TRUE))
              )
][, Geography := "England"]
formatted_forecasts <- data.table::rbindlist(
  list(formatted_forecasts, england), use.names = TRUE
)

dir.create(here::here("format-forecast", "data", "hospital-admissions"),
           showWarnings = FALSE, recursive = TRUE)

# Save forecast -----------------------------------------------------------
fwrite(
  copy(formatted_forecasts)[, date := NULL],
  paste0("format-forecast/data/hospital-admissions/", forecast_date,
         "-lshtm-hosp-adm-forecast.csv")
)

# Load observations  -----------------------------------------------------------
hosp <- setDT(readRDS(here("data/hospital_admissions.rds")))
hosp[, `:=`(Geography = region, secondary = cases)]
hosp <- hosp[date >= (forecast_date - 12 * 7)]
# Plot forecast -----------------------------------------------------------
source(here("format-forecast/utils/plot-formatted-forecast.R"))
forecasts_and_obs <- rbind(hosp, formatted_forecasts, fill = TRUE)

plot <- plot_formatted_forecast(forecasts_and_obs)

dir.create(here::here("format-forecast", "figures"),
           showWarnings = FALSE, recursive = TRUE)

ggsave(here::here("format-forecast", "figures", "admissions.png"),
  plot,
  dpi = 330, height = 12, width = 12
)
