library(plyr)
library(dplyr)
library(rvest)
library(rgdal)
library(maptools)
library(lubridate)
#library(ggmap)

# events from 2014 --------------------------------------------------------
load("data-raw/events_2014.Rdata")
events_2014 <- colwise(function(x)iconv(x, to = "utf8", from = "latin1"))(events_2014)

events_2014 <- events_2014 %>%
  mutate(bundesland = gsub("(", "", bundesland, fixed=TRUE),
         bundesland = gsub(")", "", bundesland, fixed=TRUE),
         bundesland = gsub("Bayer", "Bayern", bundesland, fixed=TRUE),
         bundesland = gsub("Bayernn", "Bayern", bundesland, fixed=TRUE),
         bundesland = gsub("Rheinland Pfalz", "Rheinland-Pfalz", bundesland, fixed=TRUE),
         bundesland = gsub("NRW", "Nordrhein-Westfalen", bundesland, fixed=TRUE),
         kategorie = gsub("(S) & (A)", "(A) & (S)", kategorie, fixed=TRUE),
         kategorie = gsub("(K) & (S)", "(S) & (K)", kategorie, fixed=TRUE),
         kategorie = gsub("(B) & (K)", "(K)", kategorie, fixed=TRUE),
         kategorie = gsub("(B) & (S)", "(S)", kategorie, fixed=TRUE),
         kategorie = gsub("(D) & (B)", "(D)", kategorie, fixed=TRUE),
         kategorie = gsub("(D) & (P)", "(D)", kategorie, fixed=TRUE),
         kategorie = gsub("(K) & (B)", "(K)", kategorie, fixed=TRUE),
         kategorie = gsub("(P) & (S)", "(S)", kategorie, fixed=TRUE),
         kategorie = gsub("(S) & (B)", "(S)", kategorie, fixed=TRUE),
         kategorie = gsub("(S) & (P)", "(S)", kategorie, fixed=TRUE),
         kategorie = gsub("(B)", NA, kategorie, fixed=TRUE),
         kategorie = gsub("(P)", NA, kategorie, fixed=TRUE),
         kategorie = gsub("(B) & (P)", NA, kategorie, fixed=TRUE),
         kategorie = gsub("(A)", "Brandanschlag", kategorie, fixed=TRUE),
         kategorie = gsub("(D)", "Kundgebung/Demo", kategorie, fixed=TRUE),
         kategorie = gsub("(K)", "Tätlicher Übergriff/Körperverletzung", kategorie, fixed=TRUE),
         kategorie = gsub("(S)", "Sonstige Angriffe auf Unterkünfte", kategorie, fixed=TRUE),
         kategorie = gsub("(A) & (S)", "Brandanschlag & Sonstige Angriffe auf Unterkünfte", kategorie, fixed=TRUE),
         kategorie = gsub("(D) & (S)", "Kundgebung/Demo & Sonstige Angriffe auf Unterkünfte", kategorie, fixed=TRUE),
         kategorie = gsub("(D) & (K)", "Kundgebung/Demo & Tätlicher Übergriff/Körperverletzung", kategorie, fixed=TRUE),
         kategorie = gsub("(S) & (K)", "Sonstige Angriffe auf Unterkünfte & Tätlicher Übergriff/Körperverletzung", kategorie, fixed=TRUE),
         ort = gsub("Sangershausen", "Sangerhausen", ort, fixed=TRUE),
         ort = gsub("Heidenheim a.d. Brenz", "Heidenheim (Brenz)", ort, fixed=TRUE),
         quelle = gsub("Quelle: ", "", quelle))

events_2014[events_2014$datum == "22.01.2014" & events_2014$ort == "Bad Dürheim", ]$ort <- "Bad Dürrheim"
events_2014[events_2014$datum == "22.01.2014" & events_2014$ort == "Bad Dürrheim", ]$bundesland <- "Baden-Württemberg"

events_2014[events_2014$datum == "28.11.2014" & events_2014$ort == "Heiden", ]$ort <- "Heidenau"

duplicate <- events_2014[events_2014$ort=="Essen und Duisburg", ]
events_2014 <- rbind(events_2014, duplicate)
events_2014[events_2014$ort=="Essen und Duisburg", ]$ort <- c("Essen", "Duisburg")

duplicate <- events_2014[events_2014$ort=="Gelsenkirchen und Witten", ]
events_2014 <- rbind(events_2014, duplicate)
events_2014[events_2014$ort=="Gelsenkirchen und Witten", ]$ort <- c("Gelsenkirchen", "Witten")


# Under Windows: Fix encoding again: even though this script is supposed to be utf-8, the above substitutions are not.
if (.Platform$OS.type == "windows") {
  events_2014$kategorie <- iconv(events_2014$kategorie, from = "latin1", to = "utf8")
}


## geocode all events from 2014
# locations <- paste(events_2014$ort, events_2014$bundesland, sep = ", ")
# locations <- enc2utf8(locations) # necessary for locations containing umlauts
# geocodes_2014 <- ggmap::geocode(locations, output = "all", source = "google", nameType = "long")
# save(geocodes_2014, file = "data-raw/geocodes_2014.Rdata")

load("data-raw/geocodes_2014.Rdata")
geocodes_2014_df <- ldply(geocodes_2014, arvig:::extract_from_geocode)
events_2014 <- tbl_df(cbind(events_2014, geocodes_2014_df))


# Due to ambiguity in the documentation of the event, the following observation is excluded:
events_2014 <- filter(events_2014, !(ort=="Heidenheim"), !(datum=="07.01.2014"))


# events from 2015 onwards ------------------------------------------------

# scrape the website (save data for quicker use)
# events_2015_later <- read_chronicle(c(2015, 2016))
# save(events_2015_later, file = "data-raw/events_2015_later.Rdata")
load("data-raw/events_2015_later.Rdata")
events_2015_later <- colwise(function(x)iconv(x, from = "utf8", to = "utf8"))(events_2015_later) # clean up encoding

# separate strings in cases of more than one category per event
events_2015_later$kategorie <- gsub("([a-z])([A-Z])","\\1 & \\2", events_2015_later$kategorie)

# Provide additional information or fix errors for correct geo-coding:
events_2015_later[events_2015_later$datum == "01.09.2015" & events_2015_later$ort == "Massow", ]$ort <- "Massow (LDS)"

events_2015_later[events_2015_later$datum == "26.03.2016" & events_2015_later$ort == "Halle" & events_2015_later$bundesland == "Sachsen", ]$bundesland <- "Sachsen-Anhalt"
events_2015_later[events_2015_later$datum == "01.06.2016" & events_2015_later$ort == "Merseburg" & events_2015_later$bundesland == "Sachsen", ]$bundesland <- "Sachsen-Anhalt"

events_2015_later[events_2015_later$datum == "23.08.2016" & events_2015_later$ort == "Wittenberge" & events_2015_later$bundesland == "Sachsen-Anhalt", ]$ort <- "Wittenberg"

events_2015_later[events_2015_later$datum == "27.01.2016" & events_2015_later$ort == "Melle" & events_2015_later$bundesland == "Nordrhein-Westfalen", ]$bundesland <- "Niedersachsen"

events_2015_later[events_2015_later$datum == "18.05.2016" & events_2015_later$ort == "Geldern" & events_2015_later$bundesland == "Niedersachsen", ]$bundesland <- "Nordrhein-Westfalen"

events_2015_later[events_2015_later$datum == "16.09.2015" & events_2015_later$ort == "Goslar" & events_2015_later$bundesland == "Hessen", ]$bundesland <- "Niedersachsen"

events_2015_later[events_2015_later$ort == "Berlin-Hohenschönhausen",]$ort <- "Neu-Hohenschönhausen, Berlin"

events_2015_later[events_2015_later$ort == "Hohenschönhausen, Berlin" & events_2015_later$datum == "22.12.2015",]$ort <- "Zingster Str./Ribnitzer Str., Berlin"

events_2015_later[events_2015_later$ort == "August",]$ort <- "Augsburg"

events_2015_later[events_2015_later$ort == "Einsiedel",]$ort <- "Einsiedel, Chemnitz"

events_2015_later[events_2015_later$ort == "Merkers",]$ort <- "Merkers-Kieselbach"

events_2015_later[events_2015_later$ort == "Naumburg" & events_2015_later$bundesland == "Sachsen",]$bundesland <- "Sachsen-Anhalt"

events_2015_later[events_2015_later$ort == "Haspe (Hagen)",]$ort <- "Haspe, Hagen"

events_2015_later[events_2015_later$ort == "Marke, Raguhn-Jeßnitz",]$ort <- "Marke"

events_2015_later <- events_2015_later[!(events_2015_later$datum == "31.03.2016" & events_2015_later$ort == "Sebnitz" & events_2015_later$bundesland == "Thüringen"), ]

events_2015_later[events_2015_later$ort == "Leverkusen" & events_2015_later$bundesland == "Niedersachsen",]$bundesland <- "Nordrhein-Westfalen"

events_2015_later <- events_2015_later[!(events_2015_later$datum == "23.01.2016" & events_2015_later$ort == "Nümbrecht" & events_2015_later$bundesland == "Niedersachsen"), ]

events_2015_later[events_2015_later$ort == "Wernberg-Köblitz" & events_2015_later$bundesland == "Berlin",]$bundesland <- "Bayern"


# Due to ambiguity as to whether this event took place in Mainz (RP) or in parts of the city of Wiesbaden (HE)
# that contain "Mainz", this event is excluded
events_2015_later <- events_2015_later[!(events_2015_later$datum == "14.11.2015" & events_2015_later$ort == "Mainz" & events_2015_later$bundesland == "Hessen"), ]

## geocode all events from 2015
locations <- paste(events_2015_later$ort, events_2015_later$bundesland, sep = ", ")
locations_unique <- unique(locations)
# geocodes_2015_later <- ggmap::geocode(locations_unique, output = "all", source = "google", nameType = "long")
# save(geocodes_2015_later, file = "./data-raw/geocodes_2015_later.Rdata")

# check for missing geocode results:
# locations_unique[which(sapply(geocodes_2015_later, function(x){x$status == "ZERO_RESULTS"}) == TRUE)]

load("data-raw/geocodes_2015_later.Rdata")
geocodes_2015_later_df <- ldply(geocodes_2015_later, arvig:::extract_from_geocode) %>%
  mutate(location = locations_unique) %>%
  right_join(data_frame(location = locations), "location")
events_2015_later <- tbl_df(cbind(events_2015_later, geocodes_2015_later_df))


# create combined data frame ----------------------------------------------
events <- rbind(events_2014, events_2015_later)


# include „Regionalschlüssel“ for each event ---------------------------------
## use shapefile to determine the respective "Regionalschlüssel" for each event.
load("data-raw/germany_250.rda")

# assign temporary event ID
events$id <- 1:nrow(events)
# map events to subregions of Germany (takes a long time)
keys <- arvig:::check_polygons(germany_250, events[ ,c("id", "lon", "lat")], key = "RS")

events <- events %>%
  left_join(keys, "id") %>%
  mutate(community_id = ifelse(ort == "Wismar", "130740087087", community_id)) %>% # necessary because the geocoded point is slightly outside the polygon
  select(-id)


# clean variable names ----------------------------------------------------
arvig <- events %>%
  select(-location) %>%
  mutate(date = dmy(datum)) %>%
  rename(location = ort,
         state = bundesland,
         description = zusammenfassung,
         `source` = quelle,
         longitude = lon,
         latitude = lat) %>%
  mutate(category_en = ifelse(kategorie == "Brandanschlag", "arson",
                           ifelse(kategorie == "Sonstige Angriffe auf Unterkünfte", "miscellaneous attack",
                                  ifelse(kategorie == "Kundgebung/Demo", "demonstration",
                                         ifelse(kategorie == "Tätlicher Übergriff/Körperverletzung", "assault",
                                                ifelse(kategorie == "Brandanschlag & Sonstige Angriffe auf Unterkünfte", "arson & miscellaneous attack",
                                                       ifelse(kategorie == "Kundgebung/Demo & Sonstige Angriffe auf Unterkünfte", "demonstration & miscellaneous attack",
                                                              ifelse(kategorie == "Kundgebung/Demo & Tätlicher Übergriff/Körperverletzung", "demonstration & assault",
                                                                     ifelse(kategorie == "Sonstige Angriffe auf Unterkünfte & Tätlicher Übergriff/Körperverletzung", "miscellaneous attack & assault",
                                                                            ifelse(kategorie == "Kundgebung/Demo & Sonstige Angriffe auf Unterkünfte & Tätlicher Übergriff/Körperverletzung", "demonstration & miscellaneous attack & assault", kategorie)))))))))) %>%
  rename(category_de = kategorie) %>%
  select(date, location, state, community_id, longitude, latitude, category_de, category_en, description, `source`) %>%
  arrange(date, community_id)


#save(arvig, file = "./data/arvig.rda")


# # fix post-geocoding errors
# load("./data/arvig.rda")
# arvig[arvig$location == "Dessau" & arvig$state == "Sachsen" & arvig$date == "2016-06-26",]$state <- "Sachsen-Anhalt"
# arvig[arvig$location == "Halle an der Saale" & arvig$state == "Sachsen" & arvig$date == "2016-08-03",]$state <- "Sachsen-Anhalt"
# save(arvig, file = "./data/arvig.rda")
