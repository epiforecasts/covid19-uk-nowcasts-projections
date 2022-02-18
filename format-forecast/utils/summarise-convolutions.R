require(data.table, quiet = TRUE)
require(purrr, quiet = TRUE, warn.conflicts = FALSE)
require(lubridate, quiet = TRUE, warn.conflicts = FALSE)
require(ggplot2, quiet = TRUE)
require(scales, quiet = TRUE, warn.conflicts = FALSE)

# load and filter
load_target <- function(
  target, dates, var = "frac_obs[1]",
  path = here("format-forecast", "posteriors", "snapshot"),
  overall_path = here("format-forecast", "posteriors", "all"),
  overall_date = "2021-06-01",
  exclude_min_weeks = 0) {
  safe_read <- safely(fread)
  targets <- map(
    dates,
    ~ safe_read(file.path(path, target, paste0(., ".csv")))[[1]]
  )
  names(targets) <- dates
  out <- rbindlist(targets, idcol = "date", use.names = TRUE)
  out <- out[, type := "snapshot"]
  out <- out[, date := as.Date(date)]
  out <- out[, .SD[date >= (min(date) + weeks(exclude_min_weeks))],
                by = "region"]

  # load overall
  overall <- safe_read(
    file.path(overall_path, target, paste0(overall_date, ".csv"))
  )[[1]]
  if (!is.null(overall)) {
    overall <- overall[, type := "all"][, date := as.Date(overall_date)]
    out <- rbind(out, overall)
  }

  out <- out[variable %in% var]
  out <- out[, target := target][, variable := NULL]
  setorder(out, region, date)
  setcolorder(out, neworder = c("target", "region", "date"))
  return(out)
}

# load all posterior estimates across targets and dates for a single parameter
load_summary <- function(
  var, targets, target_dates,
  overall_date = target_dates[length(target_dates)]) {
  safe_load_target <- safely(load_target)
  scalings <- map(targets, safe_load_target, dates = target_dates, var = var,
                  overall_date = overall_date)
  scalings <- map(scalings, ~ .[[1]])
  scalings <- rbindlist(scalings, use.names = TRUE)
  if (nrow(scalings) > 0) {
    num_col <- which(sapply(scalings, is.numeric))
    scalings[, (num_col) := lapply(.SD, signif, digits = 3), .SDcols = num_col]
  }
  return(scalings)
}

# plot scalings
plot_scaling <- function(scaling, scale_label = "scaling", scale_per = FALSE) {
  scaling <- setDT(scaling)[!is.na(median)]

  plot <- ggplot(scaling[type == "snapshot"]) +
    aes(x = date, y = median)

  if (nrow(scaling[type == "all"]) > 0) {
    plot <- plot +
      geom_hline(
        data = scaling[type == "all"],
        aes(yintercept = median), size = 1.1, alpha = 0.6,
        linetype = 2
      ) +
      geom_hline(
        data = scaling[type == "all"],
        aes(yintercept = upper_90), size = 1.1, alpha = 0.6,
        linetype = 3
      ) +
      geom_hline(
        data = scaling[type == "all"],
        aes(yintercept = lower_90), size = 1.1, alpha = 0.6,
        linetype = 3
      )
  }

  plot <- plot +
    geom_point(size = 2) +
    geom_linerange(aes(ymin = lower_90, ymax = upper_90),
      alpha = 0.3, size = 2
    ) +
    geom_linerange(aes(ymin = lower_60, ymax = upper_60),
      alpha = 0.3, size = 2
    ) +
    geom_linerange(aes(ymin = lower_30, ymax = upper_30),
      alpha = 0.3, size = 2
    ) +
    labs(x = "Date", y = scale_label) +
    guides(size = NULL) +
    theme_bw() +
    scale_x_date(date_breaks = "2 week", date_labels = "%b %d") +
    theme(axis.text.x = ggplot2::element_text(angle = 90)) +
    theme(legend.position = "bottom")

  if (scale_per) {
    plot <- plot +
      scale_y_continuous(labels = percent)
  }
  return(plot)
}

# save plot to target location
save_plot <- function(var, label, data, param, scale_per = FALSE) {
  scalings <- copy(data)
  plot <- plot_scaling(scalings[target %in% var],
    scale_label = label, scale_per = scale_per
  ) +
    expand_limits(y = 0)

  if (nrow(scalings[target %in% var]) > 0) {
    plot <- plot + facet_wrap(~region, ncol = 3)
  }

  ggsave(
    here(
      "format-forecast", "figures", "parameters",
      paste0(param, "-", var, ".png")
    ),
    plot,
    dpi = 330, height = 10, width = 10
  )
}
