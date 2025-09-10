

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
  "E_Wash_at_First" = "EjVFIFdhc2hpbmd0b24gQXZlICYgTiBGaXJzdCBTdCwgTWFkaXNvbiwgV0kgNTM3MDQsIFVTQSJmImQKFAoSCeMnhbmBUwaIEYkYcoZtUER5EhQKEgnjJ4W5gVMGiBGJGHKGbVBEeRoUChIJW_xrShFUBogRg06uQKx8kpsaFAoSCcmDLdWBUwaIEbdQz9fubXyjIgoNklqvGRUY4LzK"
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
                                 destination = "Willy_at_Ingersoll",
                                 intermediate = "E_Wash_at_First",
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

full_routes <- bind_rows(full_routes_pre,
                         jnd_olbrich, 
          jnd_milwaukee_willy, 
          jnd_milwaukee, 
          olbrich_jnd, 
          milwaukee_jnd, 
          milwaukee_jnd_willy)

board |> pin_write(full_routes, "full_routes", versioned = T, type = "rds")

