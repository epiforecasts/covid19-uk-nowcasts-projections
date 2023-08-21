require(data.table, quietly = TRUE)
require(ggplot2, quietly = TRUE)
require(lubridate, quietly = TRUE, warn.conflicts = FALSE)
suppressMessages(require(here, quietly = TRUE))

# load data
cases <- data.table::as.data.table(
  readRDS(here::here("data/test_positive_cases.rds"))
)
hosp <- data.table::setDT(readRDS(here("data/hospital_admissions.rds")))

obs <- rbind(
  cases[, type := "Test-positive cases"],
  hosp[, type := "Hospital admissions"])
obs <- obs[date > as.Date("2020-07-01")]

# make weekly
obs <- obs[, date := lubridate::floor_date(date, unit = "week", week_start = 1)]
obs <- obs[, .(cases = sum(cases, na.rm = TRUE)),
             by = c("date", "region", "type")]

# make plot
plot_nots <- function(obs) {
  obs <- data.table::copy(obs)
  data.table::setnames(obs, "type", "Data source")
  plot <- ggplot2::ggplot(obs) +
    ggplot2::aes(x = date, y = cases, col = `Data source`) +
    ggplot2::geom_point(size = 1.2) +
    ggplot2::geom_line(linewidth = 1.1, alpha = 0.8) +
    ggplot2::labs(x = "Date", y = "Notifications") +
    ggplot2::theme_bw() +
    ggplot2::scale_x_date(date_breaks = "2 week", date_labels = "%b %d") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90)) +
    ggplot2::theme(legend.position = "bottom") +
    ggplot2::scale_color_brewer(palette = "Dark2") +
    ggplot2::scale_fill_brewer(palette = "Dark2") +
    ggplot2::facet_wrap(~region, ncol = 3, scales = "free_y")

  return(plot)
}

raw_nots <- plot_nots(obs)
ggplot2::ggsave(
  here::here("data", "hosp-cases.png"),
  raw_nots,
  dpi = 330, height = 24, width = 24
)

scaled_obs <- data.table::copy(obs)
scaled_obs <- scaled_obs[, cases := cases / max(cases),
                           by = c("region", "type")]
scaled_nots <- plot_nots(scaled_obs)
ggplot2::ggsave(
  here::here("data", "scaled-hosp-cases.png"),
  scaled_nots,
  dpi = 330, height = 24, width = 24
)
