#!/bin/bash

# Convenience function that takes an arbitrary string and
# echoes its JSON-safe equivalent.
json_escape () {
    local string="$1"
    echo -n "$string" \
        | sed -e 's/"/\\"/g' \
        | tr -d "\n"
}

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
