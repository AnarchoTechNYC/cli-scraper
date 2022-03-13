FROM alpine:latest

WORKDIR "/app"

COPY [".", "."]

RUN addgroup scraper \
    && adduser --disabled-password -g "Scraper" -G scraper scraper \
    && apk add bash curl jq html-xml-utils php8 \
    && ln -s /usr/bin/php8 /usr/bin/php

USER scraper

ENTRYPOINT ["/bin/bash", "scrape.sh"]
