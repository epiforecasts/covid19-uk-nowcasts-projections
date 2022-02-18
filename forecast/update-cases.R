# Packages -----------------------------------------------------------------
library(EpiNow2, quietly = TRUE)
library(data.table, quietly = TRUE)
suppressMessages(library(here, quietly = TRUE))
suppressMessages(library(purrr, quietly = TRUE))

# Define a target date ----------------------------------------------------
target_date <- as.character(readRDS(here::here("data", "forecast_date.rds")))

# Update delays -----------------------------------------------------------
generation_time <- readRDS(
  here::here("delays", "data", "generation_time.rds")
)
incubation_period <- readRDS(
  here::here("delays", "data", "incubation_period.rds")
)
reporting_delay <- readRDS(
  here::here("delays", "data", "onset_to_case_delay.rds")
)

# Get cases  ---------------------------------------------------------------
cases <- readRDS(here::here("data/test_positive_cases.rds"))
cases <- setDT(cases)
cases <- cases[, confirm := cases][, cases := NULL]
cases <- cases[, .SD[date >= (max(date) - lubridate::weeks(12))], by = region]
data.table::setorder(cases, date)
cases <- cases[!region %in% "United Kingom"]

# Add population adjustment -----------------------------------------------
rt <- opts_list(
  rt_opts(prior = list(mean = 1.0, sd = 0.1), future = "estimate"),
  cases
)
pops <- fread(here("data", "population_2019.csv"))
pops <- pops[region_type != "phe_region"]
rt <- map(names(rt), function(x) {
  y <- rt[[x]]
  y$pop <- pops[year == 2019 & region %in% x]$population_2019
  if (length(y$pop) > 1) {
    stop("Multiple populations assigned")
  }
  return(y)
})
names(rt) <- unique(cases$region)

# # Set up cores -----------------------------------------------------
no_cores <- setup_future(cases)

# Run Rt estimation -------------------------------------------------------
regional_epinow(
  reported_cases = cases,
  generation_time = generation_time,
  delays = delay_opts(incubation_period, reporting_delay),
  horizon = 7 * 12,
  rt = rt_opts(prior = list(mean = 1, sd = 0.1)),
  obs = obs_opts(scale = list(mean = 0.497, sd = 0.01)),
  stan = stan_opts(
    samples = 4000,
    warmup = 500,
    chains = 4,
    cores = no_cores
  ),
  target_date = target_date,
  target_folder = "forecast/cases/regional",
  summary_args = list(summary_dir = paste0(
    "forecast/linelist-cases/summary/",
    target_date
  )),
  logs = "logs/linelist-cases",
  output = c("region", "summary", "samples", "timing", "fit")
)

future::plan("sequential")
