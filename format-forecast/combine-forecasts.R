require(data.table, quietly = TRUE)
require(dplyr, quietly = TRUE, warn.conflicts = FALSE)
suppressMessages(require(here, quietly = TRUE))
require(purrr, quietly = TRUE, warn.conflicts = FALSE)

# Combine death forecasts with case forecast
forecast_date <- readRDS(here::here("data", "forecast_date.rds"))

## Combine
hospital_admissions <- fread(
  here(paste0("format-forecast/data/hospital-admissions/",
              forecast_date, "-lshtm-hosp-adm-forecast.csv"))
)
deaths <- fread(
  here(paste0("format-forecast/data/deaths-using-admissions/", forecast_date,
              "-lshtm-deaths-forecast.csv"))
)
occupancy <- fread(
  here(paste0("format-forecast/data/occupancy-using-admissions/",
              forecast_date, "-lshtm-occupancy-forecast.csv"))
)
mv <- fread(
  here(paste0("format-forecast/data/mv-using-admissions/", forecast_date,
              "-lshtm-mv-forecast.csv"))
)

forecast <- rbindlist(list(
  hospital_admissions, deaths, occupancy, mv
))

round_if_numeric <- function(col) {
  if (is.numeric(col)) {
    col <- as.integer(col)
  }
  return(col)
}
forecast <- forecast[, map(.SD, round_if_numeric)]
dir.create(here::here("format-forecast", "data", "all"),
           showWarnings = FALSE, recursive = TRUE)
# Save combined
fwrite(
  forecast, 
  here::here("format-forecast", "data", "all", 
	     paste0(forecast_date, "-lshtm-forecast.csv")
  )
)
