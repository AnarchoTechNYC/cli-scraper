# CLI Scraper

Simple containerized Web scraper framework with a minimal plug-in architecture for quickly creating Web scrapers for various sites of interest.

Mostly intended to support [Anarchism.NYC](https://Anarchism.NYC/) right now.

# Using

To use this container, you supply at least the name of a scraper as its command argument. A "scraper" is just the name of a subdirectory in [the `scrapers` directory](scrapers/). For example, to invoke the `facebook.com` scraper, which scrapes Facebook.com data:

```sh
docker container build -t scraper .       # Build this container and call it `scraper`.
docker container run scraper facebook.com # Invoke the `facebook.com` scraper.
```
