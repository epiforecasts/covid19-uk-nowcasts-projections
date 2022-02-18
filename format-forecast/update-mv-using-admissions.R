library(here, quietly = TRUE)
library(future, quietly = TRUE)
library(data.table, quietly = TRUE, warn.conflicts = FALSE)

# Load observations -------------------------------------------------------
cases <- as.data.table(readRDS(here::here("data/hospital_admissions.rds")))
cases <- setDT(cases)
cases <- cases[, .(region, date = as.Date(date), primary = cases)]

beds <- readRDS(here::here("data/mv_beds.rds"))
beds <- setDT(beds)
setnames(beds, "beds", "secondary")
setcolorder(beds, neworder = c("region", "date", "secondary"))
beds <- beds[!(region %in% c("United Kingdom", "Scotland"))]

# source pipeline
source(here("format-forecast", "utils", "convolution-pipeline.R"))

# set up parallel
plan("multisession", gc = TRUE, earlySignal = TRUE)
options(mc.cores = 4)

# set forecast date
forecast_date <- readRDS(here("data", "forecast_date.rds"))

# define args
args <- list(
  primary = cases, secondary = beds,
  forecast_dir = here("forecast/admissions"),
  forecast_value = "mv_prev",
  forecast_name = "icu-using-admissions",
  return_output = FALSE,
  fit_args = list(
    delays = delay_opts(list(
      mean = 2.5, mean_sd = 1,
      sd = 0.5, sd_sd = 0.5, max = 30
    )),
    secondary = secondary_opts(type = "prevalence"),
    obs = obs_opts(
      family = "poisson",
      scale = list(mean = 0.5, sd = 0.25),
      week_effect = FALSE
    )
  )
)

convolution_pipeline_informed_prior(
  args,
  forecast_date = forecast_date,
  forecast_target = "icu",
  forecast_start = forecast_date - 12 * 7,
  overall_date = forecast_date,
  prior_weeks = 12,
  prior_scale = 1.1,
  prior_type = "all",
  prior_date = forecast_date
)
plan("sequential")
