PKGNAME := $(shell sed -n 's/Package: *\([^ ]*\)/\1/p' DESCRIPTION)
PKGVERS := $(shell sed -n 's/Version: *\([^ ]*\)/\1/p' DESCRIPTION)

.PHONY: all build check install test rd rdm clean

all: check

build:
	R CMD build .

check: build
	R CMD check --no-manual $(PKGNAME)_$(PKGVERS).tar.gz

install:
	R CMD INSTALL --preclean .

test: install
	Rscript -e 'tinytest::test_package("$(PKGNAME)")'

rd:
	Rscript -e 'roxygen2::roxygenise(".")'

rdm: install
	Rscript -e 'rmarkdown::render("README.Rmd", output_format = "github_document", quiet = TRUE, intermediates_dir = tempdir())'
	@rm -f README.html

clean:
	@rm -rf $(PKGNAME)_$(PKGVERS).tar.gz $(PKGNAME).Rcheck README.html docs
