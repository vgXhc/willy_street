library(pins)
library(tidyverse)

board <- board_s3("willy2", 
                  region = "us-east-1", 
                  access_key = Sys.getenv("S3_WILLY_KEY"), 
                  secret_access_key = Sys.getenv("S3_WILLY_SECRET"))

full_routes_pre <- pin_read(board, "full_routes")

full_routes <- full_routes_pre |> 
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

full_routes |> 
  ggplot(aes(request_time, duration, color = rush_hour)) +
  geom_point() +
  #gghighlight::gghighlight(rush_hour %in% c("am", "pm")) +
  facet_wrap(vars(direction, route_id), nrow = 2) +
  theme() +
  hrbrthemes::theme_ipsum() +
  xlab(element_blank()) +
  ylab("Traffic delay (seconds)") +
  labs(
    title = "Travel time on routes through the Madison Isthmus",
    subtitle = "Deviation of current projected from historical travel time",
    caption = "Data: Google Routes API"
  )

full_routes |> 
  filter(route_id %in% c("JND to Milwaukee via E Wash", "JND to Milwaukee via Willy")) |> 
  filter(date(request_time) == "2025-09-13") |> 
  ggplot(aes(request_time, duration, color = route_id)) +
  geom_point() +
  #gghighlight::gghighlight(rush_hour %in% c("am", "pm")) +
#  facet_wrap(vars(direction, route_id), nrow = 2) +
  theme() +
  hrbrthemes::theme_ipsum() +
  xlab(element_blank()) +
  ylab("Travel time (seconds)") +
  labs(
    title = "Travel time from JND/North Shore to E Wash/Milwaukee",
    subtitle = "via E Wash or via Willy",
    caption = "Data: Google Routes API"
  )

  