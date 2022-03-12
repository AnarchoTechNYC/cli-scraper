#!/bin/bash -
#
# This is a command-line Web scraper that turns "Upcoming Events" lists
# from Withfriends.co's Web site for a given "Movement" (organizer)
# into a FullCalendar event JSON feed. See:
#
#     https://fullcalendar.io/docs/events-json-feed
#
# It takes a single argument: the ID number of the Movement whose events
# you want to scrape.
#

# Initializations are set in the associated `data.sh` file.
#source data.sh # This is called from `scrape.sh`.

# Scrapes a single organization's events from Withfriends.co.
scrape () {
    local movement_id="$1"

    # Pull data from Withfriends.co Web site for the given "Movement" (organization/organizer).
    curl --silent -X POST --data-raw \
           "Raw=1&Metadata_Namespace=Jelly_Site_998_Container_Movement_${movement_id}_Async_Wrapper_Movement_${movement_id}_Block_New_Movement_${movement_id}_Async_Wrapper_Movement_${movement_id}_Movement_${movement_id}_Async_Wrapper" \
        "https://withfriends.co/Movement/${movement_id}/Incremental_Events:Display_Item_Element=li,Display_Item_Classes=Event_List_Item%20wf-event%20wf-front,Display_Iterator_Element=None,Display_Increment=100,Display_Template_Alias=New_List,Display_Segment=Upcoming,Display_Property_Alias=Events,Display_Item_Type=Movement,Display_Item=${movement_id}" | \
        hxnormalize -x | hxselect .wf-event > "$tmpfile"
        #hxnormalize -x | hxselect .wf-event | tee "$tmpfile" # Uncomment to show scraped page output.

    # Now we have the data, we just need to parse it.
    cat "$tmpfile" \
        | hxremove span \
        | hxpipe \
        | while read -r line; do
        #echo $line
        # If we see a new Event ID, start parsing it.
        if [[ "$line" =~ Adata-id\ CDATA\ [0-9]+ ]]; then
            local event_id=$(echo $line | cut -d ' ' -f 3)
            local event_url="${base_url}$(cat "$tmpfile" \
                | hxselect ".wf-event-link" | hxpipe \
                | grep "^Ahref.*$event_id" | cut -d ' ' -f 3)"
            local event_name=$(cat "$tmpfile" \
                | hxselect -c "h4 data[data-parent='$event_id']" \
                | tr -d '\n' | sed -e 's/  */ /g' )

            # Not all details are on the first listing page, so scrape
            # the event page itself, too.
            local event_html=$(curl --silent -X "POST" --data-raw \
                "Raw=1&Metadata_Namespace=Jelly_Site_998_Container_Event_${event_id}_Async_Wrapper" "https://withfriends.co/Event/${event_id}/Default" \
                    | hxnormalize -x \
                    | hxremove ".wf-event-partner"
            )

            # With the `event_html` scraped, we can grab its details.
            local event_location=$(echo "$event_html" \
                | hxselect -c "[data-property='Display_Address']" \
                | tr -d '\n' | sed -e 's/  */ /g'
            )
            local event_description=$(echo "$event_html" | hxselect -c ".wf-event-description" | tr '\n' ' ')

            # Parse out the time. This is tricky.
            local event_dt_human=$(echo "$event_html" \
                | hxselect -c "span[data-type='Date_Time'][id$='Time_1_New']" \
                | tr -d "\n" | sed -e 's/  */ /g'
            ) # Now `event_dt_human` probably has a string like "Saturday, March 12 at 2PM".
            # Get an ISO8601 datetime string using PHP's convenient time functions.
            local event_start_datetime=$(php -r "\$t = DateTime::createFromFormat('l, F d \at ga', '${event_dt_human}', new DateTimeZone('America/New_York')); if (\$t) { print(\$t->format('c')); }")
            # Now we have the event data, let's make a FullCalendar style
            # JSON object out of it.
            cat <<-EOF >> $outfile
{
    "title"      : "$(json_escape "$event_name")",
    "start"      : "$(json_escape "$event_start_datetime")",
    "url"        : "$(json_escape "$event_url")",
    "location"   : "$(json_escape "$event_location")",
    "description": "$(json_escape "$event_description")"
},
EOF
        fi
    done

}

main () {
    local movement_id="$1"

    # Start producing the JSON feed, a list of event objects.
    # See https://fullcalendar.io/docs/events-json-feed
    echo "[" > "$outfile" # Clobber on purpose.

    if [ -n "$movement_id" ]; then
        scrape "$movement_id"
    else
        for i in "${movement_ids[@]}"; do
            scrape "$i"
        done
    fi

    echo "]" >> "$outfile" # Finish JSON output.

    # Print it, without newlines (JSON doesn't care), and
    # fixing any trailing commas.
    #cat $outfile | tr '\n' ' ' | sed -e 's/}, ]/} ]/g'
    cat "$outfile" \
        | tr '\n' ' ' \
        | sed -e 's/}, ]/} ]/g' \
        > "/srv/scraper/$scraper.json" # Final data output.

}
main "$@"
