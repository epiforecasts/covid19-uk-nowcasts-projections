
plot_formatted_forecast <- function(forecast) {
  plot <- ggplot(forecast) +
    aes(x = date, y = Value) +
    geom_point(aes(y = secondary), alpha = 0.4) +
    geom_ribbon(aes(ymin = `Quantile 0.05`, ymax = `Quantile 0.95`),
      alpha = 0.1, size = 0.1
    ) +
    geom_ribbon(aes(col = NULL, ymin = `Quantile 0.25`, ymax = `Quantile 0.75`),
      alpha = 0.2
    ) +
    geom_line(aes(y = `Quantile 0.5`)) +
    facet_wrap(~Geography, scales = "free_y", ncol = 2) +
    scale_color_brewer(palette = "Dark2") +
    scale_fill_brewer(palette = "Dark2") +
    scale_y_log10() +
    ggplot2::theme_bw() +
    ggplot2::scale_x_date(date_breaks = "1 week", date_labels = "%b %d") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90))
  return(plot)
}
