#!/bin/bash

set -e
. setup/functions.sh

# Ensure local clone is up to date
git_refresh OpenTreeOfLife reference-taxonomy || true

# Recompile
(cd repo/reference-taxonomy; make compile bin/smasher)

# Stop the HTTP server
repo/reference-taxonomy/bin/smasher stop || true

# Restart the HTTP server
repo/reference-taxonomy/bin/smasher start
