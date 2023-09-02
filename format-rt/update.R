# Packages ----------------------------------------------------------------
require(data.table, quietly = TRUE)
require(EpiNow2, quietly = TRUE)
require(purrr, quietly = TRUE, warn.conflicts = FALSE)
require(ggplot2, quietly = TRUE)
require(lubridate, quietly = TRUE, warn.conflicts = FALSE)

# Target date -------------------------------------------------------------
creation_date <- readRDS(here::here("data", "forecast_date.rds"))
extraction_date <- creation_date

# Get national -------------------------------------------------------------
cases <- EpiNow2::get_regional_results(
  results_dir = here::here("forecast", "cases", "regional"),
  date = extraction_date
)$estimates$samples
admissions <- EpiNow2::get_regional_results(
  results_dir = here::here("forecast", "admissions", "regional"),
  date = extraction_date
)$estimates$samples

cases_admissions <- data.table::rbindlist(list(
  cases[, model := "EpiNow Cases"],
  admissions[, model := "EpiNow Admissions"]
))

# Filter out forecasts ----------------------------------------------------
growth_measures <- data.table::copy(cases_admissions)[date <= creation_date][variable %in% c("R", "growth_rate")]

# Work out doubling times -------------------------------------------------
doubling_time <- data.table::copy(growth_measures)[
  variable %in% "growth_rate",
  `:=`(
    variable = "doubling_time",
    value = log(2) / value
  )
]

# Convert gt sd -> variance -----------------------------------------------
kappa <- data.table::copy(cases_admissions)[
  variable == "gt_sd",
  .(region, model,
    variable = "kappa", value = value^2,
    date = list(unique(growth_measures[type %in% "estimate"]$date))
  )
]

generation_time <- data.table::copy(cases_admissions)[
  variable == "gt_mean",
  .(region, model,
    variable = "mean_generation_time",
    value, date = list(unique(growth_measures[type %in% "estimate"]$date))
  )
]


gt_measures <- data.table::rbindlist(list(kappa, generation_time))
gt_measures <- gt_measures[, .(date = lubridate::as_date(unlist(date))),
  by = .(region, model, value, variable)
][order(region, date)]
gt_measures <- gt_measures[!is.na(date)][, type := "estimate"]

# Extract measures of interest --------------------------------------------
combined <- data.table::rbindlist(
  list(growth_measures, doubling_time, gt_measures),
  fill = TRUE
)
combined[, c("parameter", "time", "sample", "strat") := NULL]

# Format as required ------------------------------------------------------
combined <- combined[,
  .(
    Value = median(value, na.rm = TRUE),
    `Quantile 0.05` = quantile(value, 0.05, na.rm = TRUE),
    `Quantile 0.1` = quantile(value, 0.1, na.rm = TRUE),
    `Quantile 0.15` = quantile(value, 0.15, na.rm = TRUE),
    `Quantile 0.2` = quantile(value, 0.2, na.rm = TRUE),
    `Quantile 0.25` = quantile(value, 0.25, na.rm = TRUE),
    `Quantile 0.3` = quantile(value, 0.3, na.rm = TRUE),
    `Quantile 0.35` = quantile(value, 0.35, na.rm = TRUE),
    `Quantile 0.4` = quantile(value, 0.4, na.rm = TRUE),
    `Quantile 0.45` = quantile(value, 0.45, na.rm = TRUE),
    `Quantile 0.5` = quantile(value, 0.5, na.rm = TRUE),
    `Quantile 0.55` = quantile(value, 0.55, na.rm = TRUE),
    `Quantile 0.6` = quantile(value, 0.6, na.rm = TRUE),
    `Quantile 0.65` = quantile(value, 0.65, na.rm = TRUE),
    `Quantile 0.7` = quantile(value, 0.7, na.rm = TRUE),
    `Quantile 0.75` = quantile(value, 0.75, na.rm = TRUE),
    `Quantile 0.8` = quantile(value, 0.8, na.rm = TRUE),
    `Quantile 0.85` = quantile(value, 0.85, na.rm = TRUE),
    `Quantile 0.9` = quantile(value, 0.9, na.rm = TRUE),
    `Quantile 0.95` = quantile(value, 0.95, na.rm = TRUE)
  ),
  by = c("region", "date", "variable", "model", "type")
][
  ,
  `:=`(
    Group = "LSHTM",
    `Creation Day` = lubridate::day(creation_date),
    `Creation Month` = lubridate::month(creation_date),
    `Creation Year` = lubridate::year(creation_date),
    `Day of Value` = lubridate::day(date),
    `Month of Value` = lubridate::month(date),
    `Year of Value` = lubridate::year(date),
    Geography = region,
    ValueType = variable,
    Model = model,
    Scenario = "Nowcast",
    ModelType = "Cases",
    Version = "2.0"
  )
][, region := NULL][, variable := NULL][, model := NULL]

data.table::setcolorder(combined, c(
  "Group", "Creation Day", "Creation Month", "Creation Year",
  "Day of Value", "Month of Value", "Year of Value",
  "Geography", "ValueType", "Model", "Scenario", "ModelType", "Version"
))

dir.create(here::here("format-rt", "posteriors", "summarised"),
	   recursive = TRUE, showWarnings = FALSE)

data.table::fwrite(
  combined,
  here::here("format-rt", "posteriors", "summarised", "combined.csv")
)

# Plot --------------------------------------------------------------------
last_estimate <-
  data.table::copy(combined)[type %in% "estimate"][,
    .SD[date == max(date)],
    by = .(Geography, Model, ValueType)
  ]

last_estimate <- last_estimate[, Model := ifelse(
  Model %in% "EpiNow Cases",
  "Test-positive cases", "Hospital admissions"
)]

## Linerange of just the last data point
linerange <-
  ggplot(last_estimate, aes(x = Model, y = Value, col = Model)) +
  geom_linerange(aes(ymin = `Quantile 0.05`, ymax = `Quantile 0.95`),
    alpha = 0.4, linewidth = 5
  ) +
  geom_linerange(aes(ymin = `Quantile 0.25`, ymax = `Quantile 0.75`),
    alpha = 0.4, linewidth = 5
  ) +
  facet_grid(ValueType ~ Geography, scales = "free_y") +
  scale_color_brewer(palette = "Dark2") +
  scale_fill_brewer(palette = "Dark2") +
  theme_bw() +
  theme(legend.position = "bottom",
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        strip.text.x = element_text(size = 6)) +
  labs(y = "Value", x = "", col = "Data")

dir.create(here::here("format-rt", "figures"),
	   recursive = TRUE, showWarnings = FALSE)

ggsave(here::here("format-rt", "figures", "latest.png"),
  linerange,
  dpi = 330, height = 8, width = 13
)

plot_timeseries <- function(combined, var = "R", mark_date = NULL) {
  combined <- combined[, Model := ifelse(
    Model %in% "EpiNow Cases",
    "Test-positive cases", "Hospital admissions"
  )]
  ## Complete trend
  timeseries <-
    ggplot(
      combined[ValueType %in% var],
      aes(x = date, y = Value, col = Model, fill = Model)
    ) +
    geom_ribbon(aes(ymin = `Quantile 0.05`, ymax = `Quantile 0.95`),
      alpha = 0.1, linewidth = 0.1
    ) +
    geom_ribbon(aes(col = NULL, ymin = `Quantile 0.25`, ymax = `Quantile 0.75`),
      alpha = 0.2
    ) +
    geom_hline(yintercept = 1, linetype = 2) +
    facet_wrap(~Geography, scales = "free_y", ncol = 2) +
    scale_color_brewer(palette = "Dark2") +
    scale_fill_brewer(palette = "Dark2") +
    theme_bw() +
    ggplot2::scale_x_date(date_breaks = "1 week", date_labels = "%b %d") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90)) +
    theme(legend.position = "bottom") +
    labs(y = "R", x = "Date", col = "Data", fill = "Data")

  if (!is.null(mark_date)) {
    timeseries <- timeseries +
      ggplot2::geom_vline(xintercept = mark_date, linetype = "dashed")
  }
  return(timeseries)
}

## mark estimate date as Tuesday two weeks ago
estimate_date <- floor_date(today(), "week", week_start = 1) - 13
nations <- c("United Kingdom", "England", "Scotland", "Wales", "Northern Ireland")

national_timeseries <-
  plot_timeseries(combined[Geography %in% nations], mark_date = estimate_date)

ggsave(here::here("format-rt", "figures", "national-time-series.png"),
  national_timeseries,
  dpi = 330, height = 9, width = 9
)

regional_timeseries <-
  plot_timeseries(combined[!Geography %in% nations], mark_date = estimate_date)

ggsave(here::here("format-rt", "figures", "regional-time-series.png"),
  regional_timeseries,
  dpi = 330, height = 12, width = 9
)

dir.create(here::here("format-rt", "data", "time-series"),
	   recursive = TRUE, showWarnings = FALSE)

# Report ------------------------------------------------------------------
## All estimates
data.table::fwrite(
  combined[, c("date", "type") := NULL],
  here::here("format-rt", "data", "time-series", paste0(creation_date, "-time-series-r-lshtm.csv"))
)
