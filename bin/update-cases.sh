#!/bin/bash

#Run national/regional nowcast/forecast
printf "Estimating Rt from case data and projecting\n"
Rscript forecast/update-cases.R
