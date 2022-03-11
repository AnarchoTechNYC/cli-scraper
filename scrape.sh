#!/bin/bash

main () {
    local scraper="$1"
    shift

    # Set up some utilities for every scraper.
    local tmpfile=$(mktemp)
    local outfile=$(mktemp)

    echo "Loading $scraper..." 1>&2
    # Load scraper-specific data.
    source "scrapers/$scraper/data.sh"
    # Load the actual scraper script.
    source "scrapers/$scraper/$scraper.sh"
}
main "$@"
