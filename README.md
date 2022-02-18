
# Nowcasts and Projections for Covid-19 in the UK

This repository contains the code required to: 

- Download and clean public COVID-19 surveillance data.
- Estimate the time-varying reproduction number.
- Project future hospital admissions assuming no changes in transmissibility beyond reductions in susceptibility due to infections..
- Project other dependent metrics such as fatalities, Hospital bed usage, and ICU occupancy as discrete scaled convolutions of hospital admissions and estimated parametric delay distributions.
- Produce a real-time report summarising these outputs.

## Updating estimates

See below for how to run a manual update using the provided docker container.

1. Set up the prebuilt docker container using the instructions [here](https://github.com/epiforecasts/covid19-uk-nowcasts-projections/wiki/Docker).

2. Run the following in the terminal (giving GitHub credentials when requested). On a 16 core cluster a full update should take approximately 3 hours. Either interactively in the container or programmatically. 

```
bash bin/update-forecasts.sh
```

3. Push the updated estimates to GitHub. For an example of CRON commands required to automate this process see [here](https://github.com/epiforecasts/schedule).

## Estimates

A summary report is available [here](https://epiforecasts.io/covid19-uk-nowcasts-projections/nowcast-and-projections.html) and in its raw form in `reports/nowcast-and-projections/report.Rmd`.

Individual data files are available in the following locations:

* Rt estimates can be found in `forecast/<data-source>/summary`.
* Forecasts formatted for submission can be found in `format-forecast/data/all` with plots available in `format-forecast/figures/snapshot/<target>/<date>/<target>-using-<predictor>.png`. Other plots summarising fitting and forecasting are available in the `format-forecast/figures`.
* Plots summarising convolution parameter values over time are available in the `format-forecast/figures/parameters` folder though these require careful interpretation.
* Nowcast (Rt, growth rate, incidence etc) can be found formatted for submission in `format-rt/data/all` with plots available in `format-rt/figures`.

## Submission

Forecast and nowcasts should be submitted to the validate folder found [here](https://riskawarecouk-my.sharepoint.com/personal/sowdagar_badesha_riskaware_co_uk/_layouts/15/onedrive.aspx?id=%2Fpersonal%2Fsowdagar%5Fbadesha%5Friskaware%5Fco%5Fuk%2FDocuments%2FCrystalCast%2FLSHTM%2DBusiness&originalPath=aHR0cHM6Ly9yaXNrYXdhcmVjb3VrLW15LnNoYXJlcG9pbnQuY29tLzpmOi9nL3BlcnNvbmFsL3Nvd2RhZ2FyX2JhZGVzaGFfcmlza2F3YXJlX2NvX3VrL0VwTTUya3I2OWcxSmhnNWJvX2tGa0VnQkFoUFMtWTFFQWRzdmhjMFhiWVJfV0E_cnRpbWU9UG5TSndjcy0yRWc).

## Making changes

See `bin/update-forecasts.sh` for links to the various subscripts for different tasks. Stepping through these files may also be required for debugging.