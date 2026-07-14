# Monorepo driver. Package installation and checks run in dependency order.
# Each package also includes ../../tools/package.mk for focused work.

.PHONY: all deps install purl-tests check-purled-tests models update-models check-models format check-format check-style test check rd rdm rdm-codex site clean tarball

all: test

purl-tests:
	Rscript scripts/purl-tests.R

check-purled-tests:
	Rscript scripts/purl-tests.R --check

models:
	Rscript packages/rho.ai/data-raw/compile-model-catalog.R

update-models:
	Rscript packages/rho.ai/data-raw/update-models-dev.R
	Rscript packages/rho.ai/data-raw/compile-model-catalog.R

check-models:
	Rscript packages/rho.ai/data-raw/compile-model-catalog.R --check

format:
	air format .

check-format:
	air format . --check

check-style:
	Rscript scripts/check-style.R
	air format . --check

test:
	Rscript scripts/purl-tests.R
	Rscript packages/rho.ai/data-raw/compile-model-catalog.R --check
	Rscript scripts/check-style.R
	Rscript scripts/install-all.R
	Rscript scripts/test-all.R

check:
	Rscript scripts/purl-tests.R
	Rscript packages/rho.ai/data-raw/compile-model-catalog.R --check
	Rscript scripts/check-style.R
	Rscript scripts/install-all.R
	Rscript scripts/check-all.R

rd: install
	Rscript scripts/document-all.R

rdm: install
	Rscript scripts/render-readmes.R

rdm-codex: install
	Rscript scripts/render-readmes.R "$(CREDENTIAL)"

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
