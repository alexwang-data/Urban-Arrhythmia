library(tidycensus)   # for census data
library(tidyverse)    # for data cleaning and manipulation
library(sf)           # for spatial analysis
library(jsonlite)     # for JSON export



# census api key
census_api_key("INSERT API KEY")

# define geographic parameter

# counties
NYC_COUNTIES <- c("Bronx", "Kings", "New York", "Queens", "Richmond")

# projection
CRS_NYC <- 2263 # NY State Plane Long Island Projection

# council districts
COUNCIL_DISTRICTS <- "https://services5.arcgis.com/GfwWNkhOj9bNBqoJ/arcgis/rest/services/NYC_City_Council_Districts/FeatureServer/0/query?where=1=1&outFields=*&outSR=4326&f=pgeojson"


## Council Districts
districts <- st_read(COUNCIL_DISTRICTS) %>%
  st_transform(CRS_NYC) %>%
  select(district = CounDist) %>% # keep only the district number, drop other columns
  st_make_valid() # insurance for broken geometry

# check projection
st_crs(districts)


## Blocks: Total Population, Voting Population, Non-overlapping Race Categories
# p2 table gives hispanic + non hispanic
# p4 gives voring population (18+)


block_vars <- c(
  total = "P2_001N",
  hispanic = "P2_002N",    # Hispanic or Latino
  nh_white = "P2_005N",    # White alone
  nh_black = "P2_006N",    # Black alone
  nh_native = "P2_007N",   # American Indian
  nh_asian = "P2_008N",    # Asian
  nh_pacific = "P2_009N",  # Native Hawaiian / Pacific Islander
  nh_other = "P2_010N",    # other race
  nh_multi = "P2_011N",    # two or more races
  vap_total = "P4_001N",   # voting population
  vap_hispanic = "P4_002N",
  vap_nh_white = "P4_005N",
  vap_nh_black = "P4_006N",
  vap_nh_asian = "P4_008N"
)

# why not tracts? Because tracts straddles district lines, they cross lines
# this is important because we're working with council district populations
# blocks will give more accurate results since they nest better with districts

blocks <- get_decennial(
  geography = "block",
  state = "NY",
  county = NYC_COUNTIES,
  year = 2020,
  sumfile = "pl",          # PL94-171
  variables = block_vars,
  geometry = TRUE,
  output = "wide"
) %>%
  st_transform(CRS_NYC)

# check projection
st_crs(blocks)



## st_as_sf() transform non-spatial (lon, lat) to points
## st_point_on_surface() transform polygons to points

# st_within - is A strictly inside B? The boundary doesn't count. A must be fully contained.
# st_intersect - do A and B share any space at all? Overlapping, touching at an edge.


# convert blocks to points and spatially joined with districts
blocks_pts <- blocks %>%
  st_point_on_surface() %>%
  st_join(districts, join = st_within) %>%
  st_drop_geometry() %>%     # spatial work is done, important to turn it back into a df to avoid potential errors
  filter(!is.na(district))   # remove blocks landed in no districts

pop <- blocks_pts %>%
  group_by(district) %>%
  summarise(across(all_of(names(block_vars)), ~ sum(.x, na.rm = TRUE)), .groups = "drop")


## Validate the Data

# add the total columns, get total population for the city, divide by 51 (counts of the row, cd)
ideal <- sum(pop$total) / nrow(pop)
# why not mean? Conceptually, we're looking to find the "expected population" rather than the avg district size



# calculate the difference between a district's total and the ideal band
# calculate the deviation of differences from the ideal to check population equity
pop <- pop %>%
  mutate(deviation_pct = 100 * (total - ideal ) / ideal)

nrow(pop)                   # 51 :)
sum(pop$total)              # ~ 8.8m :)
range(pop$deviation_pct)    # -2.7% to 3% < +- 5% :)



# Population Weight

# how many people from this tract live in this district?

wts <- blocks_pts %>%
  mutate(tract = str_sub(GEOID, 1, 11)) %>%   # create tract, first 11 chars = tract GEOID
  group_by(tract, district) %>%
  summarise(w = sum(total, na.rm = TRUE), .groups = "drop") %>%
  filter(w > 0)



# Census Data

# poverty_pct = 100 * sum(below) / sum(determined)

acs_vars <- c(                                  
  poverty_determined = "B17001_001E",
  poverty_below = "B17001_002E",
  population_25y_abv = "B15003_001E",
  bach_degree = "B15003_022E",
  master_degree = "B15003_023E",
  prof_degree = "B15003_024E",
  doctorate_degree = "B15003_025E",
  total_renter_households = "B25070_001E",
  income_on_rent_30_34.9 = "B25070_007E",
  income_on_rent_35_39.9 = "B25070_008E",
  income_on_rent_40_49.9 = "B25070_009E",
  income_on_rent_50_or_more = "B25070_010E"
)

acs <- get_acs(
  geography = "tract",
  state = "NY",
  county = NYC_COUNTIES,
  variables = acs_vars,
  year = 2023,
  survey = "acs5",
  output = "wide",
  geometry = FALSE
) 


econ <- wts %>%
  left_join(acs, by = c("tract" = "GEOID")) %>%
  group_by(district) %>%
  summarise(
    poverty_pct = 100 * sum(poverty_below * w, na.rm = TRUE) /
                        sum(poverty_determined * w, na.rm = TRUE),
    educ_pct = 100 * sum((bach_degree + master_degree + prof_degree +
                            doctorate_degree) * w, na.rm = TRUE) /
                     sum(population_25y_abv * w, na.rm = TRUE),
    rent_burden_pct = 100 * sum((income_on_rent_30_34.9 + income_on_rent_35_39.9 +
                                 income_on_rent_40_49.9 + income_on_rent_50_or_more) * w,
                                na.rm = TRUE) /
                            sum(total_renter_households * w, na.rm = TRUE),
    .groups = "drop"
  )


out <- pop %>%
  left_join(econ, by = "district") %>%
  mutate(
    pct_hispanic = 100 * hispanic / total,
    pct_nh_white = 100 * nh_white / total,
    pct_nh_black = 100 * nh_black / total,
    pct_nh_asian = 100 * nh_asian / total,
    pct_nh_other = 100 * (nh_native + nh_pacific + nh_other + nh_multi) / total,
    
    vap_pct_hispanic = 100 * vap_hispanic / vap_total,
    vap_pct_nh_white = 100 * vap_nh_white / vap_total,
    vap_pct_nh_black = 100 * vap_nh_black / vap_total,
    vap_pct_nh_asian = 100 * vap_nh_asian / vap_total
  ) %>%
  arrange(district)


# validation
range(rowSums(out[, c("pct_hispanic","pct_nh_white","pct_nh_black",
                      "pct_nh_asian","pct_nh_other")])) 

summary(out$poverty_pct) # max 35

sum(is.na(out$rent_burden_pct)) # 0


jsonlite::write_json(out, "council_demographics.json")


