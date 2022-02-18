#!/bin/bash

##Run national/regional nowcast/forecast
Rscript forecast/update-admissions.R

## Format the forecast for reporting
Rscript format-forecast/update-admissions.R

