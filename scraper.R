#!/usr/bin/Rscript

### Script to scrape the data from InterAction's NGO Aid Maps. ###
# 
# This scrip scrapes data from InterAction's various NGO Aid maps. 
# It combines all the data in a single data.frame and geocodes
# the provided locations based on the sources location data using
# the Google Maps API. Many of the locations can't be geolocated as
# they refer to many locations around the globe and not a single one.
# Everything is then stored in a database.


library(RCurl)
library(sqldf)

message('Loading list of maps.')
# Manually creating the list of maps and URLs to scrape.
map_name <- c('Mexico Aid Map',
              'India Aid Map',
              'China Aid Map',
              'Haiti Aid Map',
              'Food Security Aid Map',
              'Horn of Africa Aid Map',
              'Health Aid Map')

url <- c('http://mexico.ngoaidmap.org/.csv', 
         'http://india.ngoaidmap.org/.csv', 
         'http://china.ngoaidmap.org/.csv',
         'http://haiti.ngoaidmap.org/.csv',
         'http://foodsecurity.ngoaidmap.org/.csv',
         'http://hornofafrica.ngoaidmap.org/.csv',
         'http://health.ngoaidmap.org/.csv')


aid_maps <- data.frame(map_name, url)


# The scraping function. 
GetAidMapData <- function(df = aid_maps) { 
    for (i in 1:nrow(aid_maps)) {
        url <- getURL(df$url[i])
        a <- read.csv(text = url)
        a$map_name <- df$map_name[i]
        a$source <- df$url[i]
        if (i == 1) z <- a
        else z <- rbind(z, a)
    } 
    z
}

message('Fetching data.')
aid_maps_data <- GetAidMapData()

# Geocoding addresses.
message('Geocoding.')
source('code/geocode.R')

WriteTables <- function() { 
    message('Storing data in a database.')
    db <- dbConnect(SQLite(), dbname="scraperwiki.sqlite")
    if ("interaction_ngo_aid_maps" %in% dbListTables(db) == FALSE) { 
        dbWriteTable(db, 
                     "interaction_ngo_aid_maps", 
                     aid_maps_data,
                     row.names = FALSE, 
                     overwrite = TRUE)
        
        # Generating scrape metadata.
        scrape_time <- as.factor(Sys.time())
        id <- paste(ceiling(runif(1, 1, 100)), format(Sys.time(), "%Y"), sep = "_")
        new_data <- TRUE
        scraperMetadata <- data.frame(scrape_time, id, new_data)
    }
    else { 
        oldData <- dbReadTable(db, "interaction_ngo_aid_maps")
        newData <- merge(aid_maps_data, 
                         oldData, 
                         all = TRUE)
        dbWriteTable(db, 
                     "interaction_ngo_aid_maps", 
                     newData, 
                     row.names = FALSE, 
                     overwrite = TRUE)
        
        # Generating scrape metadata.
        scrape_time <- as.factor(Sys.time())
        id <- paste(ceiling(runif(1, 1, 100)), format(Sys.time(), "%Y"), sep = "_")
        new_data <- as.factor(identical(oldData, newData))
        scraperMetadata <- data.frame(scrape_time, id, new_data)
    }
    
    if ("_scraper_metadata" %in% dbListTables(db) == FALSE) {
        dbWriteTable(db, 
                     "_scraper_metadata", 
                     scraperMetadata, 
                     row.names = FALSE,
                     overwrite = TRUE)    
    }
    else { 
        dbWriteTable(db,
                     "_scraper_metadata", 
                     scraperMetadaota, 
                     row.names = FALSE, 
                     append = TRUE)  
    }
    
    # for testing purposes
    # dbListTables(db)
    # x <- dbReadTable(db, "unhcr_real_time")
    # y <- dbReadTable(db, "_scraper_metadata")
    
    dbDisconnect(db)
    message('Done!')
}

WriteTables()