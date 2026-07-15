# Publishing Rho

The monorepo has one development version. `VERSION` is authoritative, every
package `DESCRIPTION` must match it, and every dependency on another Rho
package must require at least that version.

`make public-ready` is the publication gate. It verifies version coherence,
package and monorepo news, lifecycle badges, generated tests and READMEs, the
model catalog, formatting, the parity ledger, repository history and working
tree, installed behavior, source tarballs, and package sites. A non-verified
row in `docs/pi-parity.md` is a failure, not a release note.

The secret scan uses Gitleaks 8.30.1 over the complete Git history. The Linux
x86-64 release archive has SHA-256 digest
`551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb`.
CI installs that exact artifact; local runs must provide the same `gitleaks`
executable on `PATH`.

Before changing repository visibility:

1. Run `make rd` and `make rdm`, then commit the generated namespaces,
   manuals, tests, model catalog, and package READMEs.
2. Complete every fixture and external-account row in the Pi parity ledger.
3. Run `make public-ready` from the commit that will become public.
4. Require green R 4.4 and R-release checks for that commit.
5. Confirm that the pinned nanonext streaming commit is public and available
   to the R-universe build graph.

After those conditions hold, change `sounkou-bioinfo/Rho` to public, enable the
pkgdown deployment workflow, and add the repository and its nanonext dependency
to `sounkou-bioinfo/sounkou-bioinfo.r-universe.dev`.
