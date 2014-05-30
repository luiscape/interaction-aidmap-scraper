#!/usr/bin/Rscript

#### Geocoding a data.frame ####
#
# This script geocodes a data.frame using a string column
# as input. It stores the resulting latitude and longitude
# columns as extra columns to the original data.frame.

library(rjson)

### Geocoding function ###
ConstructGeocodeUrl <- function(address, return.call = "json", sensor = "false") {
    root <- "http://maps.google.com/maps/api/geocode/"
    u <- paste(root, return.call, "?address=", address, "&sensor=", sensor, sep = "")
    return(URLencode(u))
}

gGeoCode <- function(df, verbose = FALSE) {

    # Create progress bar.
    pb <- txtProgressBar(min = 0, max = nrow(df), style = 3)

    for (i in 1:nrow(df)) {  # Google Geocoding API has a 2500 limit per 24 hours.
        setTxtProgressBar(pb, i)  # Updates progress bar.
        if (nchar(as.character(df$location[i])) > 30) {
            latitude <- NA
            longitude <- NA
            a <- data.frame(latitude, longitude)
        }
        else {
            address <- as.character(gsub(">", " ", df$location[i]))
            if(verbose) cat(address,"\n")
            u <- ConstructGeocodeUrl(address)
            doc <- getURL(u)
            x <- fromJSON(doc)
            if(x$status=="OK") {
                latitude <- x$results[[1]]$geometry$location$lat
                longitude <- x$results[[1]]$geometry$location$lng
                a <- data.frame(latitude, longitude)

            } else {
                latitude <- NA
                longitude <- NA
                a <- data.frame(latitude, longitude)
            }
        }
        if (i == 1) b <- a
        else b <- rbind(b, a)
    }
    z <- cbind(df, b)
    z
}

aid_maps_data <- gGeoCode(aid_maps_data)