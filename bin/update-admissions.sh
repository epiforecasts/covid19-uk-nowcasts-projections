#!/bin/bash

##Run national/regional nowcast/forecast
printf "Estimating Rt from admissions data\n"
Rscript forecast/update-admissions.R

## Format the forecast for reporting
printf "Processing admissions projections\n"
Rscript format-forecast/update-admissions.R

