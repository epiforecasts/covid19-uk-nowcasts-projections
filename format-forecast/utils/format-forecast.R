
# Packages ----------------------------------------------------------------
require(EpiNow2, quietly = TRUE)
require(data.table, quietly = TRUE)
suppressMessages(require(lubridate, quietly = TRUE))


# forecast_date -> date forecast was made
format_forecast <- function(forecasts, forecast_date = NULL,
                            forecast_value = "hospital_inc",
                            model_type, quantile_scaling = 1,
                            shrink_per = 0,
                            version = "1.0",
                            scenario = "MTP") {

  ## Shrink forecast
  if (shrink_per > 0) {
    forecasts <- forecasts[order(cases)][, .SD[round(.N * shrink_per, 0):round(.N * (1 - shrink_per), 0)],
      by = .(region, date)
    ]
  }

  ## Scale diff from median forecast using a scaling parameter
  scaled_quantile <- function(cases, prob, scaling = quantile_scaling, type = "lower") {
    if (quantile_scaling == 1) {
      scaled_q <- quantile(cases, prob, na.rm = TRUE)
    } else {
      med <- median(cases, na.rm = TRUE)
      q <- quantile(cases, prob, na.rm = TRUE)
      q_diff <- abs(median - q)
      scaled_q_diff <- q_diff * scaling
      if (type %in% "lower") {
        scaled_q <- median - scaled_q_diff
      } else if (type %in% "upper") {
        scaled_q <- median + scaled_q_diff
      }
    }
    return(scaled_q)
  }

  forecasts <- forecasts[date >= forecast_date][,
    .(
      Value = median(cases, na.rm = TRUE),
      `Quantile 0.05` = scaled_quantile(cases, 0.05),
      `Quantile 0.1` = scaled_quantile(cases, 0.1),
      `Quantile 0.15` = scaled_quantile(cases, 0.15),
      `Quantile 0.2` = scaled_quantile(cases, 0.2),
      `Quantile 0.25` = scaled_quantile(cases, 0.25),
      `Quantile 0.3` = scaled_quantile(cases, 0.3),
      `Quantile 0.35` = scaled_quantile(cases, 0.35),
      `Quantile 0.4` = scaled_quantile(cases, 0.4),
      `Quantile 0.45` = scaled_quantile(cases, 0.45),
      `Quantile 0.5` = quantile(cases, 0.5, na.rm = TRUE),
      `Quantile 0.55` = scaled_quantile(cases, 0.55, type = "upper"),
      `Quantile 0.6` = scaled_quantile(cases, 0.6, type = "upper"),
      `Quantile 0.65` = scaled_quantile(cases, 0.65, type = "upper"),
      `Quantile 0.7` = scaled_quantile(cases, 0.7, type = "upper"),
      `Quantile 0.75` = scaled_quantile(cases, 0.75, type = "upper"),
      `Quantile 0.8` = scaled_quantile(cases, 0.8, type = "upper"),
      `Quantile 0.85` = scaled_quantile(cases, 0.85, type = "upper"),
      `Quantile 0.9` = scaled_quantile(cases, 0.9, type = "upper"),
      `Quantile 0.95` = scaled_quantile(cases, 0.95, type = "upper")
    ),
    by = .(region, date)
  ][order(region, date)][
    ,
    `:=`(
      `Creation Day` = lubridate::day(forecast_date),
      `Creation Month` = lubridate::month(forecast_date),
      `Creation Year` = lubridate::year(forecast_date),
      `Day of Value` = lubridate::day(date),
      `Month of Value` = lubridate::month(date),
      `Year of Value` = lubridate::year(date),
      "Group" = "LSHTM",
      "Model" = "EpiNow",
      "Scenario" = scenario,
      "ModelType" = model_type,
      AgeBand = "All",
      Version = version,
      `ValueType` = forecast_value,
      "Geography" = region
    )
  ][, region := NULL]

  forecasts <- data.table::setcolorder(
    forecasts,
    c(
      "Group", "Creation Day", "Creation Month",
      "Creation Year", "Day of Value", "Month of Value",
      "Year of Value", "Geography", "ValueType", "Model",
      "Scenario", "ModelType", "Version", "Value", "AgeBand"
    )
  )
  return(forecasts)
}
