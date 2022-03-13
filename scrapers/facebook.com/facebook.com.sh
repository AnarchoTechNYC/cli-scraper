#!/bin/bash -
#
# This is a command-line Web scraper that turns "Upcoming Events" lists
# from Facebook.com's Web site for a given Page (organizer/venue, etc.)
# into a FullCalendar event JSON feed. See:
#
#     https://fullcalendar.io/docs/events-json-feed
#
# It takes a single argument: the HTTP POST data already prepared referencing
# the `pageID` and the `doc_id` you want to scrape. E.g., to scrape data for
# the venue TV Eye in New York City, use its `pageID` of `113957910012325`
# and its upcoming events "document" with `doc_id` of `5182274978466320`.
#
#     variables=%7B%22pageID%22%3A%22113957910012325%22%7D&doc_id=5182274978466320

# Initializations are set in the associated `data.sh` file.
#source data.sh # This is called from `scrape.sh`.

# Scrapes a single Page's events from Facebook.com.
# This produces a well-formed JSON array in `${outfile}`.
scrape () {
    local http_post_vars="$1"

    # Pull data from Withfriends.co Web site for the given "Movement" (organization/organizer).
    curl --silent -X POST --data-raw \
           "$http_post_vars" \
        "https://www.facebook.com/api/graphql/" \
        > "$tmpfile" # This should produce some JSON in GraphQL format.

    # Now we have the data, we just need to parse it.
    jq '.data.page.upcoming_events.edges | map_values(
        . + {"x-fullcalendar.io": {"title": .node.name, "start": .node.time_range.start, "end": (.node.startTimestampForDisplay + 60 * 60 * 2 | todateiso8601), "url": ("https://www.facebook.com/events/" + .node.id), "location": .node.event_place.contextual_name}}
    ) | [.[]["x-fullcalendar.io"]]' "$tmpfile" > "$outfile"
}

main () {
    local http_post_body="$1"

    if [ -n "$http_post_body" ]; then
        scrape "$http_post_body"
    else
        for i in "${http_post_vars[@]}"; do
            scrape "$i"
        done
    fi

    cat "$outfile" \
        > "/srv/scraper/$scraper.json" # Final data output.
}

main "$@"
