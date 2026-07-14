# Monorepo driver. Package installation and checks run in dependency order.
# Each package also includes ../../tools/package.mk for focused work.

.PHONY: all deps install purl-tests check-purled-tests format check-format check-style test check rd rdm site clean tarball

all: test

purl-tests:
	Rscript scripts/purl-tests.R

check-purled-tests:
	Rscript scripts/purl-tests.R --check

format:
	air format .

check-format:
	air format . --check

check-style:
	Rscript scripts/check-style.R
	air format . --check

test:
	Rscript scripts/purl-tests.R
	Rscript scripts/check-style.R
	Rscript scripts/install-all.R
	Rscript scripts/test-all.R

check:
	Rscript scripts/purl-tests.R
	Rscript scripts/check-style.R
	Rscript scripts/install-all.R
	Rscript scripts/check-all.R

rd: install
	Rscript scripts/document-all.R

rdm:
	Rscript -e 'rmarkdown::render("README.Rmd", output_format = "github_document", quiet = TRUE)'
	@rm -f README.html

site: install
	Rscript scripts/build-site.R

install:
	Rscript scripts/install-all.R

deps:
	Rscript install-deps.R
	Rscript scripts/dependency-graph.R

clean:
	@rm -rf *.Rcheck _site README.html Rplots.pdf
	@find packages -type d -name '*.Rcheck' -prune -exec rm -rf {} +
	@find packages -type d -name '_site' -prune -exec rm -rf {} +
	@find packages -type f \( -name '*.tar.gz' -o -name 'README.html' \) -delete

tarball:
	tar --exclude='.git' --exclude='_site' --exclude='*.Rcheck' -czf rho-real.tar.gz .
