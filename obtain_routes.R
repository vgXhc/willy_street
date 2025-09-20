library(httr2)
library(pins)
library(tidyverse)

board <- board_s3("willy2", 
                  region = "us-east-1", 
                  access_key = Sys.getenv("S3_WILLY_KEY"), 
                  secret_access_key = Sys.getenv("S3_WILLY_SECRET"))

full_routes_pre <- pin_read(board, "full_routes")


# a list of origins and destinations, using Google's PlaceID format. 
# PlaceIDs can be interactively obtained here: https://developers.google.com/maps/documentation/places/web-service/place-id
OD <- list(
  "JND_at_North_Shore" = "EjJKb2huIE5vbGVuIERyICYgTiBTaG9yZSBEciwgTWFkaXNvbiwgV0kgNTM3MDMsIFVTQSJmImQKFAoSCXu5mjo7UwaIEQoMsRKsOd_lEhQKEgl7uZo6O1MGiBEKDLESrDnf5RoUChIJjfKfA-BSBogRYsWXJvaejFUaFAoSCXuIPEYlUwaIEXg83UWw3DMxIgoNpX6rGRXEzrjK",
  "Olbrich_boat_launch" = "ChIJ5TFo0_BTBogRiLW3n_CHw1g",
  "Willy_at_Ingersoll" = "EjZXaWxsaWFtc29uIFN0ICYgUyBJbmdlcnNvbGwgU3QsIE1hZGlzb24sIFdJIDUzNzAzLCBVU0EiZiJkChQKEgl5M0JHcVMGiBGPw2HWAUYh8hIUChIJeTNCR3FTBogRj8Nh1gFGIfIaFAoSCU95EHRxUwaIEWK02CjjGAaNGhQKEgnVLyMUcVMGiBGluqGTTsODeCIKDeLLrRkVHs-7yg",
  "E_Wash_at_Milwaukee" = "EjdFIFdhc2hpbmd0b24gQXZlICYgTWlsd2F1a2VlIFN0LCBNYWRpc29uLCBXSSA1MzcwNCwgVVNBImYiZAoUChIJUc7xKnFUBogRwRIyIhvYO_MSFAoSCVHO8SpxVAaIEcESMiIb2DvzGhQKEglb_GtKEVQGiBGDTq5ArHySmxoUChIJ384s9rVWBogRKuqY4yFj-BEiCg2_lLAZFXd5vso",
  "E_Wash_at_First" = "EjVFIFdhc2hpbmd0b24gQXZlICYgTiBGaXJzdCBTdCwgTWFkaXNvbiwgV0kgNTM3MDQsIFVTQSJmImQKFAoSCeMnhbmBUwaIEYkYcoZtUER5EhQKEgnjJ4W5gVMGiBGJGHKGbVBEeRoUChIJW_xrShFUBogRg06uQKx8kpsaFAoSCcmDLdWBUwaIEbdQz9fubXyjIgoNklqvGRUY4LzK",
  "Wilson_at_Willy" = "EjNFIFdpbHNvbiBTdCAmIFdpbGxpYW1zb24gU3QsIE1hZGlzb24sIFdJIDUzNzAzLCBVU0EiZiJkChQKEgnhym9La1MGiBGcY9ohN_QfmhIUChIJ4cpvS2tTBogRnGPaITf0H5oaFAoSCfVVbLltUwaIEeqhwVpfun4hGhQKEglPeRB0cVMGiBFitNgo4xgGjSIKDdbmrBkVlla6yg",
  "Eastwood_at_Winnebago" = "EjJFYXN0d29vZCBEciAmIFdpbm5lYmFnbyBTdCwgTWFkaXNvbiwgV0kgNTM3MDQsIFVTQSJmImQKFAoSCeNrPLqDUwaIEffZcIG93NP9EhQKEgnjazy6g1MGiBH32XCBvdzT_RoUChIJ9SfChYZTBogRf5DI8zHQBHYaFAoSCVkZZw6HUwaIESCTKdLOYzU9IgoNnNiuGRW5G73K"
)


#Define the request body as a list
request_body <- list(
  origin = list(),
  destination = list(),
  intermediates = list(),
  travelMode = "DRIVE",
  routingPreference = "TRAFFIC_AWARE",
  computeAlternativeRoutes = FALSE,
  languageCode = "en-US",
  units = "METRIC"
)

# main function to obtain route
get_route <- function(origin, destination, intermediate, request_body) {

# Built the API request
response <- request("https://routes.googleapis.com/directions/v2:computeRoutes") %>%
  req_method("POST") %>%
  req_headers(
    "Content-Type" = "application/json",
    "X-Goog-Api-Key" = Sys.getenv("ROUTES_API_KEY"),
    "X-Goog-FieldMask" = "routes.duration,routes.description,routes.staticDuration,routes.distanceMeters,routes.polyline.encodedPolyline"
  ) %>%
  req_body_json(request_body) %>%
  req_body_json_modify(origin = list(
    placeId = OD[[origin]]),
    destination = list(
      placeId = OD[[destination]]
    ),
    intermediates = list(
      placeId = OD[[intermediate]]
    )) |> 
  req_perform()

# Parse the response
result <- response %>% resp_body_json()

routes <- result$routes[[1]]
# Return the results as named list
return(tibble(
  origin = origin,
  destination = destination,
  intermediate = intermediate,
  distance = routes$distanceMeters,
  duration = routes$duration,
  static_duration = routes$staticDuration,
  polyline = routes$polyline$encodedPolyline,
  request_time = Sys.time()
))
}

jnd_olbrich <- get_route(origin = "JND_at_North_Shore",
          destination = "Olbrich_boat_launch",
          intermediate = "Willy_at_Ingersoll",
          request_body = request_body)

jnd_milwaukee <- get_route(origin = "JND_at_North_Shore",
                           destination = "E_Wash_at_Milwaukee",
                           intermediate = "E_Wash_at_First",
                           request_body = request_body)
jnd_milwaukee_willy <- get_route(origin = "JND_at_North_Shore",
                                 intermediate = "Willy_at_Ingersoll",
                                 destination = "E_Wash_at_Milwaukee",
                                 request_body = request_body)

olbrich_jnd <- get_route(origin = "Olbrich_boat_launch",
                         destination = "JND_at_North_Shore",
                         intermediate = "Willy_at_Ingersoll",
                         request_body = request_body)

milwaukee_jnd <- get_route(destination = "JND_at_North_Shore",
                           origin = "E_Wash_at_Milwaukee",
                           intermediate = "E_Wash_at_First",
                           request_body = request_body)

milwaukee_jnd_willy <- get_route(destination = "JND_at_North_Shore",
                                 origin = "E_Wash_at_Milwaukee",
                                 intermediate = "Willy_at_Ingersoll",
                                 request_body = request_body)

hairball_eastwood <- get_route(origin = "Wilson_at_Willy",
                               destination = "Eastwood_at_Winnebago",
                               intermediate = "Willy_at_Ingersoll",
                               request_body = request_body)
eastwood_hairball <- get_route(destination = "Wilson_at_Willy",
                               origin = "Eastwood_at_Winnebago",
                               intermediate = "Willy_at_Ingersoll",
                               request_body = request_body)

full_routes <- bind_rows(
  full_routes_pre,
  jnd_olbrich,
  jnd_milwaukee_willy,
  jnd_milwaukee,
  olbrich_jnd,
  milwaukee_jnd,
  milwaukee_jnd_willy,
  hairball_eastwood,
  eastwood_hairball
)

board |> pin_write(full_routes,
                   "full_routes",
                   versioned = TRUE,
                   type = "rds")

full_routes |> write_csv(file = "data/data_raw.csv")

# basic data cleaning and variable creation
full_routes_clean <- full_routes |> 
  filter(!(origin == "JND_at_North_Shore" & destination == "Willy_at_Ingersoll")) |> 
  mutate(route_id = case_when(
    origin == "JND_at_North_Shore" & 
      destination == "Olbrich_boat_launch" & 
      intermediate == "Willy_at_Ingersoll" ~ "JND to Olbrich",
    origin == "Olbrich_boat_launch" &
      destination == "JND_at_North_Shore" &
      intermediate == "Willy_at_Ingersoll" ~ "Olbrich to JND",
    origin == "E_Wash_at_Milwaukee" &
      destination == "JND_at_North_Shore" &
      intermediate == "E_Wash_at_First" ~ "Milwaukee to JND via E Wash",
    destination == "E_Wash_at_Milwaukee" &
      origin == "JND_at_North_Shore" &
      intermediate == "E_Wash_at_First" ~ "JND to Milwaukee via E Wash",
    origin == "E_Wash_at_Milwaukee" &
      destination == "JND_at_North_Shore" &
      intermediate == "Willy_at_Ingersoll" ~ "Milwaukee to JND via Willy",
    destination == "E_Wash_at_Milwaukee" &
      origin == "JND_at_North_Shore" &
      intermediate == "Willy_at_Ingersoll" ~ "JND to Milwaukee via Willy",
    destination == "Wilson_at_Willy" &
      origin == "Eastwood_at_Winnebago" &
      intermediate == "Willy_at_Ingersoll" ~ "Eastwood to Hairball",
    origin == "Wilson_at_Willy" &
      destination == "Eastwood_at_Winnebago" &
      intermediate == "Willy_at_Ingersoll" ~ "Hairball to Eastwood"),
    duration = as.integer(str_remove(duration, "s")),
    static_duration = as.integer(str_remove(static_duration, "s")),
    traffic_delay = duration - static_duration,
    direction = case_match(route_id,
                           c("JND to Olbrich",
                             "JND to Milwaukee via E Wash",
                             "JND to Milwaukee via Willy",
                             "Hairball to Eastwood") ~ "EB",.default = "WB"),
    day_of_week = wday(request_time, label = TRUE),
    weekend = ifelse(day_of_week %in% c("Sat", "Sun"), TRUE, FALSE), 
    rush_hour = case_when(
      !weekend & (hour(request_time) == 7 | (hour(request_time) == 8 & minute(request_time) <= 30)) ~ "am",
      !weekend & (hour(request_time) == 16 | (hour(request_time) == 17 & minute(request_time) <= 30)) ~ "pm",
      .default = NA)
  ) |>
  filter(!is.na(route_id))

#saveRDS(full_routes_clean, file = "data/data_clean.RDS")
write_csv(full_routes_clean, file = "data/data_clean.csv")
  
