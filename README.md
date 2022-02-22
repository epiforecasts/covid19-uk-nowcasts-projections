
# Nowcasts and Projections for COVID-19 in the UK

This repository contains the code required to: 

- Download and clean public COVID-19 surveillance data.
- Estimate the time-varying reproduction number.
- Project future hospital admissions assuming no changes in transmissibility beyond reductions in susceptibility due to infections.
- Project other dependent metrics such as fatalities, Hospital bed usage, and mechanical ventilation bed occupancy as discrete scaled convolutions of hospital admissions and estimated parametric delay distributions.
- Produce a real-time report summarising these outputs.

## Updating estimates

See below for how to run a manual update using the provided docker container.

1. Optionally: set up the prebuilt docker container using the instructions [here](https://github.com/epiforecasts/covid19-uk-nowcasts-projections/wiki/Docker). Alternatively the estimates can be created outside of docker but dependencies will have to be installed manually.

2. Run the following in the terminal (giving GitHub credentials when requested). On a 16 core cluster a full update should take approximately 3 hours. Either interactively in the container or programmatically. 

```
bash bin/update-forecasts.sh
```

3. Save the estimates, for example pushing to a clone of the repo in GitHub. For an example of CRON commands required to automate this process see [here](https://github.com/epiforecasts/schedule/blob/main/jobs/spim.sh).

## Estimates

A summary report is available in the `docs/` directory. The latest version can be accessed [here](https://epiforecasts.io/covid19-uk-nowcasts-projections/nowcast-and-projections.html). Its source is in `reports/nowcast-and-projections/report.Rmd`.

Individual data files and figures are available in the following locations:

* Formatted nowcasts (Rt, growth rate, etc) can be found in `format-rt/data/all` with plots available in `format-rt/figures`.
* Formatted projections can be found in `format-forecast/data/all` with plots available in `format-forecast/figures/snapshot/<target>/<date>/<target>-using-<predictor>.png`. Other plots summarising fitting and forecasting are available in the `format-forecast/figures`.
* Plots summarising convolution parameter values over time are available in the `format-forecast/figures/parameters` folder though these require careful interpretation.

## Making changes

See `bin/update-forecasts.sh` for links to the various subscripts for different tasks. Stepping through these files may also be required for debugging.
