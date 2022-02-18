# Packages -----------------------------------------------------------------
library(EpiNow2, quietly = TRUE)
library(data.table, quietly = TRUE)
suppressMessages(library(here, quietly = TRUE))
library(purrr, quietly = TRUE, warn.conflicts = FALSE)

# Define a target date ----------------------------------------------------
target_date <- as.character(readRDS(here::here("data", "forecast_date.rds")))

# Update delays -----------------------------------------------------------
generation_time <- readRDS(here::here("delays", "data", "generation_time.rds"))
incubation_period <-
  readRDS(here::here("delays", "data", "incubation_period.rds"))
reporting_delay <-
  readRDS(here::here("delays", "data", "onset_to_admission_delay.rds"))

# Get cases  ---------------------------------------------------------------
cases <- as.data.table(readRDS(here::here("data/hospital_admissions.rds")))
cases <- setDT(cases)
cases <- cases[, .(region, date = as.Date(date), confirm = cases)]
cases <- cases[, .SD[date >= (max(date) - lubridate::weeks(12))], by = region]
data.table::setorder(cases, date)
cases <- cases[!region %in% "United Kingdom"]

# # Set up cores -----------------------------------------------------
if (!interactive()) {
  ## If running as a script enable this
  options(future.fork.enable = TRUE)
}
no_cores <- setup_future(cases)

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

# Run Rt estimation -------------------------------------------------------
regional_epinow(
  reported_cases = cases,
  generation_time = generation_time,
  delays = delay_opts(incubation_period, reporting_delay),
  horizon = 7 * 12,
  rt = rt,
  obs = obs_opts(scale = list(mean = 0.0214, sd = 0.01)),
  stan = stan_opts(
    samples = 4000,
    warmup = 500,
    chains = 4,
    cores = no_cores
  ),
  target_date = target_date,
  target_folder = "forecast/admissions/regional",
  summary_args = list(summary_dir = paste0(
    "forecast/admissions/summary/",
    target_date
  )),
  logs = "logs/admissions",
  output = c("region", "summary", "samples", "timing", "fit")
)

future::plan("sequential")
