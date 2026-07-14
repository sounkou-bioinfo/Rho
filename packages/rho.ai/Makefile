include ../../tools/package.mk

.PHONY: models update-models check-models

models:
	Rscript data-raw/compile-model-catalog.R

update-models:
	Rscript data-raw/update-models-dev.R
	Rscript data-raw/compile-model-catalog.R

check-models:
	Rscript data-raw/compile-model-catalog.R --check
