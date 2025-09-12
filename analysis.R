full_routes_pre |> 
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
      intermediate == "Willy_at_Ingersoll" ~ "JND to Milwaukee via Willy"),
    duration = as.integer(str_remove(duration, "s"))
  ) |> 
  filter(!is.na(route_id)) |> 
  ggplot(aes(request_time, duration, color = route_id)) +
  geom_point() +
  facet_wrap(~ route_id) +
  theme(legend.position = "none")

  