require(data.table, quietly = TRUE)
require(ggplot2, quietly = TRUE)
require(purrr, quietly = TRUE, warn.conflicts = FALSE)
suppressMessages(require(here, quietly = TRUE))

# load helper functions
source(here("format-forecast", "utils", "summarise-convolutions.R"))

# get available dates and targets
start_date <- as.Date("2021-10-05")
forecast_date <- as.Date(readRDS(here("data", "forecast_date.rds")))
target_dates <- seq(from = start_date, to = forecast_date, by = "week")
targets <- c("admissions", "deaths", "mv", "occupancy")

dir.create(here("format-forecast", "posteriors", "summarised"),
	   showWarnings = FALSE, recursive = TRUE)

# summarise all parameters
scaling <- load_summary(var = "frac_obs[1]", targets, target_dates)
fwrite(scaling, here("format-forecast", "posteriors", "summarised", "scalings.csv"))

delay_mean <- load_summary(var = "delay_mean[1]", targets, target_dates)
fwrite(delay_mean, here("format-forecast", "posteriors", "summarised", "delay_mean.csv"))

delay_sd <- load_summary(var = "delay_sd[1]", targets, target_dates)
fwrite(delay_sd, here("format-forecast", "posteriors", "summarised", "delay_sd.csv"))

dir.create(here("format-forecast", "posteriors", "summarised"),
	   showWarnings = FALSE, recursive = TRUE)

dir.create(here("format-forecast", "figures", "parameters"),
	   showWarnings = FALSE, recursive = TRUE)

# save plots for scaling
save_plot("admissions", "Case hospitalisation ratio", scaling, "scaling",
  scale_per = TRUE
)
save_plot("deaths", "Hospitalisation fatality ratio", scaling, "scaling",
  scale_per = TRUE
)
save_plot("mv", "Hospitalisation to MV bed occupancy ratio", scaling, "scaling",
  scale_per = TRUE
)

# save plots for mean log of the delay distribution
save_plot("admissions", "Log mean delay from case to hospitalisation",
  delay_mean, "delay-mean"
)
save_plot("deaths", "Log mean delay from hospitalisation to death",
  delay_mean, "delay-mean"
)
save_plot("mv", "Log mean MV bed stay duration", delay_mean, "delay-mean")

save_plot("occupancy", "Log mean hospital stay duration",
  delay_mean, "delay-mean")


# save plots for log standard deviation of the delay distribution
save_plot("admissions",
  "Log standard deviation delay from case to hospitalisation",
  delay_sd, "delay-sd")
save_plot("deaths",
  "Log standard deviation delay from hospitalisation to death",
  delay_sd, "delay-sd")
save_plot("mv", "Log standard deviation of MV bed stay duration",
  delay_sd, "delay-sd")
save_plot("occupancy", "Log standard deviation of hospital stay duration",
  delay_sd, "delay-sd")
