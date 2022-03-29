#!/bin/bash

Rscript -e "rmarkdown::render(here::here('reports', 'nowcast-and-projections', 'report.Rmd'))"

mkdir docs 2> /dev/null
mv reports/nowcast-and-projections/report.html docs/index.html

echo Report moved to docs/index.html

mv reports/severity/report.html docs/severity.html

echo Severity report moved to docs/severity.html
