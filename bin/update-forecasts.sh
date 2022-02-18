#!/bin/bash

# Update data repo
bash bin/update-data.sh

# Update delays if data has changed
ash bin/update-delays.sh

# Run national/regional case nowcast/forecast 
bash bin/update-admissions.sh

# Update linelist based case estimates
bash  bin/update-cases.sh

# Report latest R estimate
Rscript format-rt/update.R

# Update downstream forecasts
bash bin/update-downstream-forecasts.sh

# Combine forecasts
Rscript format-forecast/combine-forecasts.R

# Update convolution summary
Rscript format-forecast/update-convolutions-summaries.R

# Update summary reports
bash bin/update-summary-reports.sh
