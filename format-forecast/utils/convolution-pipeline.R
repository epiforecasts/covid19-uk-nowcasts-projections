# Packages ----------------------------------------------------------------
library(EpiNow2, quietly = TRUE, warn.conflicts = FALSE)
library(data.table, quietly = TRUE, warn.conflicts = FALSE)
suppressMessages(library(here, quietly = TRUE, warn.conflicts = FALSE))
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(purrr, quietly = TRUE, warn.conflicts = FALSE)
library(ggplot2, quietly = TRUE, warn.conflicts = FALSE)
library(cowplot, quietly = TRUE, warn.conflicts = FALSE)
library(future, quietly = TRUE, warn.conflicts = FALSE)
library(devtools, quietly = TRUE, warn.conflicts = FALSE)
library(lubridate, quietly = TRUE, warn.conflicts = FALSE)

# load the prototype regional_secondary function
source("https://raw.githubusercontent.com/seabbs/regional-secondary/master/regional-secondary.R")

# load formatting
source(here("format-forecast/utils/format-forecast.R"))

# load plotting
source(here("format-forecast/utils/plot-formatted-forecast.R"))

# source get posteriors
source(here("format-forecast", "utils", "get-posteriors.R"))

convolution_pipeline <- function(primary, secondary, forecast_date,
                                 forecast_dir, forecast_target,
                                 forecast_name, forecast_value,
                                 type = "snapshot", priors = NULL,
                                 obs_weeks = 8,
                                 window = c(as.integer(2 * 7)),
                                 fit_args = list(), forecast = TRUE,
                                 return_output = FALSE) {
  # verbose info on what is happening
  message(
    "Processing: ", forecast_target, " for the ", forecast_date,
    " target date.")

  # override some setting for a meta setting
  type <- match.arg(type, choices = c("snapshot", "all"))
  if (type %in% "all") {
    message("Using all available data for fitting (with a two week burn in)")
    window <- NULL
  }
  # set data.table cores
  setDTthreads(4)

  # load observed data
  observations <- merge(primary, secondary, by = c("date", "region"))
  observations <- observations[date <= forecast_date]
  observations <- observations[!is.na(primary)][!is.na(secondary)]

  if (!is.null(obs_weeks)) {
    observations <- observations[,
      .SD[date >= (max(date) - lubridate::weeks(obs_weeks))],
      by = region
    ]
  }
  setorder(observations, date)

  # Check observations
  if (nrow(observations) == 0) {
    stop("No observed data in target window")
  }
  if (any(is.na(observations$primary))) {
    stop("NAs in primary cases in target windo")
  }
  if (any(is.na(observations$secondary))) {
    stop("NAs in secondary cases in target window")
  }

  # Load forecasts ----------------------------------------------------------
  if (forecast) {
    forecasts <- get_regional_results(
      results_dir = file.path(forecast_dir, "regional"),
      date = forecast_date, forecast = TRUE, samples = TRUE
    )$estimated_reported_cases$samples
    forecasts <- forecasts[date >= min(observations$date)]
    forecasts <- forecasts[sample <= 1000]
  } else {
    forecasts <- NULL
  }

  # Forecast deaths from cases ----------------------------------------------
  estimates <- do.call(
    regional_secondary, c(
      list(
        reports = observations,
        case_forecast = forecasts,
        window = window,
        control = list(adapt_delta = 0.99, max_treedepth = 15),
        return_fit = FALSE, return_plots = TRUE, verbose = TRUE,
        priors = priors
      ),
      fit_args
    )
  )

  plot_path <- here("format-forecast", "figures", type,
                    forecast_target, forecast_date)
     if (!dir.exists(plot_path)) {
      dir.create(plot_path, recursive = TRUE)
    }


  # Format forecasts --------------------------------------------------------
  if (forecast) {
    setnames(estimates$samples, "value", "cases", skip_absent = TRUE)
    formatted_forecasts <- format_forecast(estimates$samples,
      forecast_value = forecast_value,
      version = "2.0",
      forecast_date = forecast_date,
      shrink_per = 0,
      model_type = "Cases"
    )

    formatted_forecasts <- formatted_forecasts[!Geography %in% "England"]
    england <- copy(formatted_forecasts)[!Geography %in% c("Scotland", "Wales",
     "Northern Ireland", "United Kingdom"),
      lapply(.SD, sum, na.rm = TRUE),
      by = setdiff(colnames(formatted_forecasts), c("Geography", "Value",
      grep("Quantile", colnames(formatted_forecasts), value = TRUE))),
      .SDcols = c("Value",
                  eval(grep("Quantile", colnames(formatted_forecasts),
                       value = TRUE)))
    ][, Geography := "England"]
    formatted_forecasts <- rbindlist(
      list(formatted_forecasts, england),
       use.names = TRUE
      )

    # Save forecast -----------------------------------------------------------
    dir.create(here::here("format-forecast", "data", forecast_name),
               showWarnings = FALSE, recursive = TRUE)
    fwrite(
      copy(formatted_forecasts)[, date := NULL],
      here::here("format-forecast", "data", forecast_name, 
                 paste0(forecast_date, "-lshtm-", forecast_target, "-forecast.csv"))
    )

    # Plot forecast -----------------------------------------------------------
    forecasts_and_obs <- rbind(
      observations [, Geography := region],
      formatted_forecasts,
      fill = TRUE
    )

    plot <- plot_formatted_forecast(forecasts_and_obs)
    ggsave(
      file.path(plot_path, paste0(forecast_name, ".png")),
      plot,
      dpi = 330, height = 12, width = 12
    )
  }

  # save plots
  walk2(estimates$region, names(estimates$region), function(f, n) {
    walk(
      1:length(f$plots),
      ~ suppressMessages(ggsave(
        filename = paste0(n, "-", names(f$plots)[.], ".png"),
        plot = f$plots[[.]] + ggplot2::theme_bw(),
        path = paste0(plot_path, "/"),
        height = 6, width = 12
      ))
    )
  })

  dir.create(here::here("format-forecast", "posteriors", type, forecast_target),
             showWarnings = FALSE, recursive = TRUE)

  # Extract posterior estimates and save
  fwrite(
      estimates$summarised_posterior,
      here("format-forecast", "posteriors", type,
           forecast_target, paste0(forecast_date, ".csv"))
  )

  if (return_output) {
    return(estimates)
  } else {
    return(invisible(NULL))
  }
}


# fit the pipeline to all and a snapshot
convolution_pipeline_informed_prior <- function(
  args,
  forecast_date,
  forecast_target,
  forecast_start = as.Date("2021-04-13"),
  overall_date = forecast_date,
  overall_loc = here("format-forecast", "posteriors", "all"),
  prior_weeks = 12, prior_type = "all", prior_date = forecast_date,
  prior_scale = 1.1
  ) {
  if (forecast_date < forecast_start) {
    forecast <- FALSE
  }else{
    forecast <- TRUE
  }

  if (overall_date == forecast_date) {
    overall_file <- file.path(overall_loc, forecast_target,
                               paste0(overall_date, ".csv"))
    if (!file.exists(overall_file)) {
      do.call(
        convolution_pipeline,
          c(
            list(
              type = "all",
              obs_weeks = prior_weeks,
              forecast_date = forecast_date,
              forecast_target = forecast_target,
              forecast = FALSE
            ),
          args
        )
      )
    }
  }

  # fit to snapshot using all data posterior by 1.2 fold
  do.call(
    convolution_pipeline,
    c(
      list(
        forecast_date = forecast_date,
        forecast_target = forecast_target,
        type = "snapshot",
        priors = get_posteriors(
          date = prior_date,
          target = forecast_target,
          type = prior_type,
          scale_sd = prior_scale
        ),
        forecast = forecast
      ),
      args
    )
  )
  return(invisible(NULL))
}
