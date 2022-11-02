#!bin/bash

printf "Get data\n"
Rscript data/get-data.R

printf "Updating the target forecast date to today\n"
## Rscript data/forecast-date.R

printf "Plotting available data\n"
Rscript data/plot-data.R


