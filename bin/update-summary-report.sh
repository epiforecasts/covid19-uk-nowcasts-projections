#!/bin/bash

Rscript -e "rmarkdown::render(here::here('reports', 'nowcast-and-projections', 'report.Rmd'))"

mkdir docs 2> /dev/null
mv reports/nowcast-and-projections/report.html docs/index.html

echo Report moved to docs/index.html
