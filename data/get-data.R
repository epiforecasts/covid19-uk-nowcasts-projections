require(dplyr, quietly = TRUE, warn.conflicts = FALSE)
suppressMessages(require(here, quietly = TRUE))
require(readr, quietly = TRUE)

cases_deaths_local <-
  suppressMessages(read_csv(paste0(
    "https://api.coronavirus.data.gov.uk/v2/data?areaType=ltla&",
    "metric=newCasesBySpecimenDate&metric=newDeaths28DaysByDeathDate&",
    "format=csv"
  )))

cases_deaths_national <-
  suppressMessages(read_csv(paste0(
    "https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&",
    "metric=newCasesBySpecimenDate&metric=newDeaths28DaysByDeathDate&",
    "format=csv"
  )))

hospital_cases_regional <-
  suppressMessages(read_csv(paste0(
    "https://api.coronavirus.data.gov.uk/v2/data?areaType=nhsRegion&",
    "metric=covidOccupiedMVBeds&metric=newAdmissions&metric=hospitalCases&",
    "format=csv"
  )))

hospital_cases_national <-
  suppressMessages(read_csv(paste0(
    "https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&",
    "metric=covidOccupiedMVBeds&metric=newAdmissions&metric=hospitalCases&",
    "format=csv"
  )))

ltla_nhser <- readRDS(here::here("data", "ltla_nhser.rds"))

# test positive cases -----------------------------------------------------
cases_deaths <- cases_deaths_local %>%
  dplyr::rename(ltla_name = areaName) %>%
  dplyr::inner_join(ltla_nhser, by = "ltla_name") %>%
  dplyr::group_by(date, nhse_region) %>%
  dplyr::summarise_if(is.numeric, sum) %>%
  dplyr::ungroup() %>%
  dplyr::rename(areaName = nhse_region) %>%
  dplyr::bind_rows(cases_deaths_national)

hospital_cases <- hospital_cases_regional %>%
  dplyr::bind_rows(hospital_cases_national)

test_positive_cases <- cases_deaths %>%
  dplyr::select(date, region = areaName, cases = newCasesBySpecimenDate) %>%
  dplyr::filter(!is.na(cases))

saveRDS(test_positive_cases, here::here("data/test_positive_cases.rds"))

# hospital_admissions -----------------------------------------------------
hospital_admissions_truncation <- c(
  `Northern Ireland` = 4,
  Wales = 4
)
hospital_admissions <- hospital_cases %>%
  dplyr::select(date, region = areaName, cases = newAdmissions) %>%
  dplyr::filter(!is.na(cases)) %>%
  dplyr::mutate(truncation = hospital_admissions_truncation[region]) %>%
  tidyr::replace_na(list(truncation = 0)) %>%
  dplyr::group_by(region) %>%
  dplyr::filter(date <= max(date) - truncation) %>%
  dplyr::select(date, region, cases)

saveRDS(hospital_admissions, here::here("data/hospital_admissions.rds"))

# deaths ---------------------------------------------------------
death_truncation <- 4
deaths <-  cases_deaths %>%
  dplyr::select(date, region = areaName,
                deaths = newDeaths28DaysByDeathDate) %>%
  dplyr::filter(!is.na(deaths)) %>%
  dplyr::group_by(region) %>%
  dplyr::filter(date <= max(date) - death_truncation) 

saveRDS(deaths, here::here("data/deaths.rds"))

# hospital beds -----------------------------------------------------------
hospital_beds <- hospital_cases %>%
  dplyr::select(date, region = areaName, beds = hospitalCases) %>%
  dplyr::filter(!is.na(beds))
saveRDS(hospital_beds, here::here("data/hospital_beds.rds"))

# mechanical ventilation beds ---------------------------------------------
mv_beds <- hospital_cases %>%
  dplyr::select(date, region = areaName, beds = covidOccupiedMVBeds) %>%
  dplyr::filter(!is.na(beds))

saveRDS(mv_beds, here::here("data/mv_beds.rds"))
