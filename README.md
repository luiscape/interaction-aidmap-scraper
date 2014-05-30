InterAction Aid Map Scraper
===========================

Scraper that extracts data from CSV files available in the various [InterAction's NGO Aid Maps](http://ngoaidmap.org). The scraper combines all the source map files into a single data.frame, making it easier for analysis. The scraper also geocodes the provided locations using Google Maps API. (However, many locations can't be mapped as a single point as they refer to many different locations.) The final result is stored in a database.

The scraper was designed to run in ScraperWiki.