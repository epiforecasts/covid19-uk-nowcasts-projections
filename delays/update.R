# Packages ----------------------------------------------------------------
library(EpiNow2)
library(data.table)
library(future)
library(here)

# Save incubation period and generation time ------------------------------
generation_time <- get_generation_time(
  disease = "SARS-CoV-2",
  source = "ganyani",
  max_value = 15
)
incubation_period <- get_incubation_period(
  disease = "SARS-CoV-2",
  source = "lauer",
  max_value = 15
)

saveRDS(generation_time, here::here("delays", "data", "generation_time.rds"))
saveRDS(incubation_period,
        here::here("delays", "data", "incubation_period.rds"))

# Set up parallel ---------------------------------------------------------
if (!interactive()) {
  ## If running as a script enable this
  options(future.fork.enable = TRUE)
}
future::plan(multiprocess)

# Fit delay from onset to admission ---------------------------------------
linelist <- readRDS(here::here("delays", "data", "pseudo_linelist.rds"))
linelist <- as.data.table(linelist)

onset_to_admission_delay <- estimate_delay(linelist$report_delay,
  bootstraps = 100,
  bootstrap_samples = 250, max_value = 15
)

saveRDS(onset_to_admission_delay,
        here::here("delays", "data", "onset_to_admission_delay.rds"))

# Fit delay from onset to case ------------------------------------------
case_delays <- readRDS(here::here("delays", "data", "test_delays.rds"))

onset_to_case_delay <- estimate_delay(case_delays,
  bootstraps = 100,
  bootstrap_samples = 250, max_value = 15
)

saveRDS(onset_to_case_delay,
        here::here("delays", "data", "onset_to_case_delay.rds"))

# Fit delay from onset to deaths ------------------------------------------
deaths <- readRDS(here("delays", "data", "deaths.rds"))

onset_to_death_delay <- estimate_delay(deaths,
  bootstraps = 100,
  bootstrap_samples = 250, max_value = 30
)

saveRDS(onset_to_death_delay,
        here::here("delays", "data", "onset_to_death_delay.rds"))
