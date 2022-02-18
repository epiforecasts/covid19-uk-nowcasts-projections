# Packages ----------------------------------------------------------------
suppressMessages(require(here, quietly = TRUE))
require(future, quietly = TRUE)
require(data.table, quietly = TRUE, warn.conflicts = FALSE)

# Load observations -------------------------------------------------------
cases <- as.data.table(readRDS(here::here("data/test_positive_cases.rds")))
cases <- setDT(cases)
cases <- cases[, .(region, date = as.Date(date), primary = cases)]

hosp <- setDT(readRDS(here("data/hospital_admissions.rds")))
setnames(hosp, "cases", "secondary")

# source pipeline
source(here("format-forecast", "utils", "convolution-pipeline.R"))

# set up parallel
plan("multicore", gc = TRUE, earlySignal = TRUE)
options(mc.cores = 4)

# set forecast date
forecast_date <- readRDS(here("data", "forecast_date.rds"))

# define args
args <- list(
  primary = cases, secondary = hosp,
  forecast_dir = here("forecast/cases"),
  forecast_value = "hospital_inc",
  forecast_name = "admissions-using-cases",
  return_output = FALSE,
  fit_args = list(
    delays = delay_opts(list(
      mean = 2.5, mean_sd = 1,
      sd = 0.5, sd_sd = 0.5, max = 30
    )),
    secondary = secondary_opts(type = "incidence"),
    obs = obs_opts(
      scale = list(mean = 0.2, sd = 0.1),
      week_effect = TRUE
    )
  )
)

convolution_pipeline_informed_prior(
  args,
  forecast_date = forecast_date,
  forecast_target = "admissions",
  forecast_start = forecast_date - 12 * 7,
  overall_date = forecast_date,
  prior_weeks = 12,
  prior_scale = 1.1,
  prior_type = "all",
  prior_date = forecast_date
)
plan("sequential")
