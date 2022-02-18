#!/bin/bash

# Update the regional secondary function  as needed
cd regional-secondary
git pull
cd ..

# Make a admissions forecast using cases
Rscript format-forecast/update-admissions-using-cases.R

# Make a deaths forecast using admissions
Rscript format-forecast/update-deaths-using-admissions.R

# Make a hospital bed usage forecast using admissions
Rscript format-forecast/update-occupancy-using-admissions.R

# Make a mechanical ventilation bed usage forecast using admissions
Rscript format-forecast/update-mv-using-admissions.R
