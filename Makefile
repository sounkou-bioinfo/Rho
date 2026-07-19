# Monorepo driver. Package installation and checks run in dependency order.
# Each package also includes ../../tools/package.mk for focused work.

.PHONY: all deps hooks install purl-tests check-purled-tests models update-models update-copilot-models check-models format check-format check-style check-version check-publication check-parity check-secrets public-ready test check rd rdm rdm-codex site clean tarball

all: test

hooks:
	git config core.hooksPath .githooks

purl-tests:
	Rscript scripts/purl-tests.R

check-purled-tests:
	Rscript scripts/purl-tests.R --check

models:
	Rscript packages/rho.ai/data-raw/compile-model-catalog.R

update-models:
	Rscript packages/rho.ai/data-raw/update-models-dev.R
	Rscript packages/rho.ai/data-raw/update-github-copilot-models.R --credential="$(CREDENTIAL)"
	Rscript packages/rho.ai/data-raw/compile-model-catalog.R

update-copilot-models:
	Rscript packages/rho.ai/data-raw/update-github-copilot-models.R --credential="$(CREDENTIAL)"
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

check-version:
	Rscript scripts/check-version.R

check-publication:
	Rscript scripts/check-publication.R

check-parity:
	Rscript scripts/check-parity.R

check-secrets:
	Rscript scripts/check-secrets.R

public-ready: check-version check-publication check-purled-tests check-models check-style check-parity check-secrets
	$(MAKE) test
	$(MAKE) check
	$(MAKE) site

test:
	Rscript scripts/purl-tests.R
	Rscript packages/rho.ai/data-raw/compile-model-catalog.R --check
	Rscript scripts/check-style.R
	Rscript scripts/install-all.R
	Rscript scripts/test-all.R

check:
	Rscript scripts/check-version.R
	Rscript scripts/check-publication.R
	Rscript scripts/purl-tests.R --check
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
	Rscript scripts/build-landing.R
	Rscript scripts/build-project-docs.R

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
