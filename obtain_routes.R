#key is in ROUTES_API_KEY

library(mapsapi)

route <- mp_directions(key = Sys.getenv("ROUTES_API_KEY"),
                       origin = "172 John Nolen Dr, Madison, WI 53715", 
                       destination = "Olbrich Park Boat Launch, 3401 Atwood Ave, Madison, WI 53704")


library(httr2)

# a list of origins and destinations, using Google's PlaceID format. 
# PlaceIDs can be interactively obtained here: https://developers.google.com/maps/documentation/places/web-service/place-id
OD <- list(
  "JND_at_North_Shore" = "EjJKb2huIE5vbGVuIERyICYgTiBTaG9yZSBEciwgTWFkaXNvbiwgV0kgNTM3MDMsIFVTQSJmImQKFAoSCXu5mjo7UwaIEQoMsRKsOd_lEhQKEgl7uZo6O1MGiBEKDLESrDnf5RoUChIJjfKfA-BSBogRYsWXJvaejFUaFAoSCXuIPEYlUwaIEXg83UWw3DMxIgoNpX6rGRXEzrjK",
  "Olbrich_boat_launch" = "ChIJ5TFo0_BTBogRiLW3n_CHw1g",
  "Willy_at_Ingersoll" = "EjZXaWxsaWFtc29uIFN0ICYgUyBJbmdlcnNvbGwgU3QsIE1hZGlzb24sIFdJIDUzNzAzLCBVU0EiZiJkChQKEgl5M0JHcVMGiBGPw2HWAUYh8hIUChIJeTNCR3FTBogRj8Nh1gFGIfIaFAoSCU95EHRxUwaIEWK02CjjGAaNGhQKEgnVLyMUcVMGiBGluqGTTsODeCIKDeLLrRkVHs-7yg",
  "E_Wash_at_Milwaukee" = "EjdFIFdhc2hpbmd0b24gQXZlICYgTWlsd2F1a2VlIFN0LCBNYWRpc29uLCBXSSA1MzcwNCwgVVNBImYiZAoUChIJUc7xKnFUBogRwRIyIhvYO_MSFAoSCVHO8SpxVAaIEcESMiIb2DvzGhQKEglb_GtKEVQGiBGDTq5ArHySmxoUChIJ384s9rVWBogRKuqY4yFj-BEiCg2_lLAZFXd5vso"
)

origins_destinations$JND_at_North_Shore
#Define the request body as a list
request_body <- list(
  origin = list(
    placeId = "EikxNzIgSm9obiBOb2xlbiBEciwgTWFkaXNvbiwgV0kgNTM3MTUsIFVTQSIxEi8KFAoSCXu5mjo7UwaIETr2Hgb_iyscEKwBKhQKEgmN8p8D4FIGiBFixZcm9p6MVQ"
    ),
  destination = list(
    placeId = "ChIJ5TFo0_BTBogRiLW3n_CHw1g"
  ),
  travelMode = "DRIVE",
  routingPreference = "TRAFFIC_AWARE",
  computeAlternativeRoutes = FALSE,
  languageCode = "en-US",
  units = "METRIC"
)

request_body |> req_body_json_modify(origin = list(
  placeId = OD$JND_at_North_Shore))

# Make the API request
response <- request("https://routes.googleapis.com/directions/v2:computeRoutes") %>%
  req_method("POST") %>%
  req_headers(
    "Content-Type" = "application/json",
    "X-Goog-Api-Key" = Sys.getenv("ROUTES_API_KEY"),
    "X-Goog-FieldMask" = "routes.duration,routes.staticDuration,routes.distanceMeters,routes.polyline.encodedPolyline"
  ) %>%
  req_body_json(request_body) %>%
  req_body_json_modify(origin = list(
    placeId = OD$JND_at_North_Shore)) |> 
  req_dry_run()

# Parse the response
result <- response %>% resp_body_json()

# View the result
str(result)