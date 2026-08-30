#!/bin/bash
# Regenerates the Packages file (and compressed variants) from everything
# inside the debs/ folder. Run this locally on Linux (or WSL) after adding
# new .deb files, then commit and push.
#
# Requires: dpkg-dev (apt-get install dpkg-dev)

set -e

cd "$(dirname "$0")"

if ! command -v dpkg-scanpackages &> /dev/null; then
  echo "dpkg-scanpackages not found. Install it with: sudo apt-get install dpkg-dev"
    exit 1
    fi

    dpkg-scanpackages debs /dev/null > Packages
    gzip -k -f Packages
    bzip2 -k -f Packages

    echo "Done. Packages, Packages.gz and Packages.bz2 updated."
    echo "Now commit and push (or let the GitHub Action do it automatically)."
    
