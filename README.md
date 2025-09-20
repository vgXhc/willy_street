# willy_street
Using Google Maps API to get real-time traffic data during the Willy Street trial

You can read more about the background of this [on my blog](https://haraldkliems.netlify.app/posts/2025-09-13-using-the-google-routes-api-to-collect-travel-time-data-during-a-traffic-trial/).

## Data
A raw data set is committed after each run in [`data/data_raw.csv`](data/data_raw.csv). Unless you have a good reason to use the raw data, you should use one of the cleaned files instead. Those create a number of additional variables to facilitate analysis (see codebook below) and remove entries with incorrect or incomplete data. The clean data is available as a [`csv`](data/data_clean.csv) or [`RDS`](data/data_clean.RDS) file.

## Codebook


| Variable | type | values |
| --- | --- | --- |
| `origin` | string | Starting location of route |
| `destination` | string | Destination of route |
| `intermediate` | string | Forced intermediate waypoint on route (to ensure consistent routing) |
| `distance` | integer | route distance in meters |
| `duration` | integer | route duration in seconds, with traffic conditions at `request_time` |
| `duration_minutes` | numeric | route duration in minutes (derived from `duration`) |
| `static_duration` | integer | route duration in seconds, "considering only historical traffic information" |
| `polyline` | string | Google [polyline](https://developers.google.com/maps/documentation/utilities/polylinealgorithm) encoded coordinates of the route |
| `request_time` | POSIX date/time | Time at which the route was calculated, using local Madison time |
| `route_id` | string | human-readable short description of the route |
| `traffic_delay` | int | difference between travel time with current traffic and using only historical traffic (i.e. `duration - static_duration`) |
| `direction` | string | Whether the route travels eastbound (`EB`) or westbound (`WB`) through the isthmus |
| `day_of_week` | ordered factor | Abbreviated day of week (`Mon`, `Tue`, etc.) |
| `weekend` | Boolean | Was the route calculated on a weekend (`TRUE`) or not (`FALSE`) |
| `rush_hour` | string | Was the route calculated when the rush hour lanes would have been in effect? Possible values are `am` and `pm` (may later replace this with TRUE/FALSE to take into account the relevant `direction`) |

