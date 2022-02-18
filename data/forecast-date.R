suppressMessages(require(here, quietly = TRUE))

forecast_date <- Sys.Date()
saveRDS(forecast_date, here::here("data", "forecast_date.rds"))
