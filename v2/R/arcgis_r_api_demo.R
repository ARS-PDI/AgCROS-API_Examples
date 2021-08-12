# ArcGIS REST API Demo Script
#
# Root API URL: https://pdihosting.azurecloudgov.us/arcgis/rest/services/AgCROS
#
# Author: Josh Birlingmair (@joshbmair)

# Uncomment the following line if you need to install any of these packages
# install.packages(c('httr', 'jsonlite', 'arcpullr'))

library(httr)
library(jsonlite)
library(arcpullr)

base_url =
  'https://pdihosting.azurecloudgov.us/arcgis/rest/services/AgCROS/COFOARD4/'

# Query ArcGIS REST API to for feature services for a specific location
resp = GET(sprintf('%s%s', base_url, 'FeatureServer?f=json'))

if (resp$status_code != 200) {
  print('Error: failed to retrieve feature services')
}

# Transform JSON response to data frame 
lyrs_df = fromJSON(rawToChar(resp$content))$layers
View(lyrs_df)

# Make a list of the rows
rows = lyrs_df[[1]]
lyr_map = list()
i = 1

while (i <= length(rows)) {
  lyr_map[[i]] = lyrs_df[i, 2]
  i = i + 1
}

# Find the table called 'MetaUnits_Unit'
i = 1

while (i <= length(rows)) {
  if (lyr_map[[i]] == 'MetaUnits_Unit') {
    break
  }
  
  i = i + 1
}

# Layer ID = index - 1
ftr_lyr_url = sprintf('%s%s%d', base_url, 'FeatureServer/', i - 1)
ftr_lyr = get_spatial_layer(ftr_lyr_url)
View(ftr_lyr)

# Display number of records
print(length(ftr_lyr[[1]]))

# Display the first record's Unit ID
print(ftr_lyr[[2]][1])

# Display 5 records
View(head(ftr_lyr, 5))

# Find the measurement or management layer with the most records
i = max_num_records = 1

# NOTE: This loop will may take a while to finish as it has to query a several
# thousand records
while (i < length(lyrs_df[[1]])) {
  if (startsWith(lyrs_df[i, 2], 'Meas') | startsWith(lyrs_df[i, 2], 'Mgt')) {
    
    lyr_url = sprintf('%s%s%d', base_url, 'FeatureServer/', i - 1)
    lyr = get_spatial_layer(lyr_url)
    
    num_records = length(lyr[[1]])
    
    print(num_records)
    
    if (num_records > max_num_records) {
      max_num_records = num_records
      max_ftr_lyr = lyr
    }
  }
  
  i = i + 1
}

# Display layer with most records (NOTE: this likely will take a moment)
View(max_ftr_lyr)

# Calculate basic statistics of a subset of the table's records
mean_2000 = mean(head(ftr_lyr, 2000)$co2_gc_ha_d)
median_2000 = median(head(ftr_lyr, 2000)$co2_gc_ha_d)
print(mean_2000)
print(median_2000)

# Save a subset of the records of the layer `MeasGHGFlux_Unit` (the layer with
# the most records) to a file
write.csv(head(max_ftr_lyr, 2000),
          'C:\\Users\\Public\\Downloads\\max_ftr_lyr.csv')

# Calculate basic statistics of the full table's records
mean_full = mean(ftr_lyr$co2_gc_ha_d)
median_full = median(ftr_lyr$co2_gc_ha_d)
print(mean_full)
print(median_full)

# Save the records of the layer `MeasGHGFlux_Unit` (the layer with # the most
# records) to a file
write.csv(max_ftr_lyr,
          'C:\\Users\\Public\\Downloads\\max_ftr_lyr.csv')
