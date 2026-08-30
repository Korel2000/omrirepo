# Sileo Repo

Minimal APT source structure for Sileo (jailbroken iPhone package manager), hosted on GitHub Pages.

## Setup

1. Settings -> Pages -> Build and deployment -> Source: GitHub Actions
2. Push a .deb file into debs/ and the Action rebuilds Packages and deploys automatically.
3. Add the repo to Sileo: Sources -> + -> paste https://<username>.github.io/<repo-name>/

## Local build (optional)

Run ./generate.sh on Linux/WSL with dpkg-dev installed to regenerate Packages before pushing.

## Structure

- debs/ - put .deb files here
- Packages, Packages.gz, Packages.bz2 - auto-generated, do not edit by hand
- generate.sh - local build script
- index.html - simple landing page
- .github/workflows/ - CI automation
