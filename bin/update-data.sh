#!bin/bash

printf "Get data \n"
Rscript data/get-data.R

printf "Updating the target forecast date to today"
Rscript data/forecast-date.R

printf "Plotting available data"
Rscript data/plot-data.R


