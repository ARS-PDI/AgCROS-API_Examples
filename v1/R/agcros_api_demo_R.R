###############################################################################################################
# DEMO script showing how to extract data from the AgCROS API
#
# AgCROS API: https://gpsr.ars.usda.gov/agcrospublicapi/swagger
# Created: 21 July 2021
# Author: Lindsey Messinger - translated python script originally written by Roger Marquez (agcros_api_demo.py)
###############################################################################################################

install.packages(c('httr', 'jsonlite', 'tidyverse'))

library(httr)
library(jsonlite)
library(tidyverse)

res = GET("https://gpsr.ars.usda.gov/agcrospublicapi/swagger") # submit a request to the API server

apiBase = "https://gpsr.ars.usda.gov/AgCROSpublicapi/api/v1"


###############################################################
##### Query the experimenal units table in the API server #####
###############################################################

expUnitUrl = "/ExperimentalLayout/Experunits"

expUnitUrl = paste(apiBase, expUnitUrl, sep = "")

resp = GET(expUnitUrl)

if (resp$status_code != 200) {
  # checks the status code of the get response. 200 is a successful response.
  print("Error: failed to retrieve exp units") # error message returned if the GET query is unsuccessful - could be an issue with URL, etc.
}

# convert results to dataframe to manipulate
units = fromJSON(rawToChar(resp$content))
units = units$result

# get unique sites and sort alphabetically
uniqueSites = sort(unique(units$siteId))
print(uniqueSites[1],) # print the first site in the the sorted list

# get all unitids for cofoard4
cofoard4Units = units[units$siteId == "COFOARD4",]

######################################
##### Query a particular unit ID #####
######################################

selUnit = cofoard4Units[1,] #selects the first row in the cofoard4Units data element

gfluxUrl = "/Measurement/GreenhouseGasFlux"
gfluxUrl = paste(apiBase, gfluxUrl, sep = "")
limit = "&limit=2000"

gfluxUrl = GET(paste0(gfluxUrl, "?expUnitId=", selUnit$expUnitId, limit)) #### LATER: May want to clean this up

if (gfluxUrl$status_code != 200) {
  # checks the status code of the get response. 200 is a successful response.
  print("Error: failed to retrieve exp units") # error message returned if the GET query is unsuccessful - could be an issue with URL, etc.
}

results = fromJSON(rawToChar(gfluxUrl$content))

print(paste("Num Records for", selUnit$expUnitId, ":", results$resultCount))

##################################################
##### Query all units for the indicated site #####
##################################################

# treatment/units need to be explicity called: expUnitId=exp1&expUnitId=exp2...

baseghgfluxUrl = paste(apiBase, "/Measurement/GreenhouseGasFlux?", sep = "")

for (exp in cofoard4Units['expUnitId']) {
  tempUrl = paste("expUnitId=", exp, "&", sep = "")
  print(tempUrl)
}

ghgfluxUrl = paste0(baseghgfluxUrl, paste0(tempUrl, collapse = ""))

resp = GET(paste0(ghgfluxUrl, limit)) # limit is defined earlier in the script, line 53

if (resp$status_code != 200) {
  # checks the status code of the get response. 200 is a successful response.
  print("Error: failed to retrieve exp units") # error message returned if the GET query is unsuccessful - could be an issue with URL, etc.
}

# can see how many results are here:

results = fromJSON(rawToChar(resp$content))


print(paste("Total # of results:", results$totalCount))
print(paste("Returned # of results:", results$resultCount))
print(paste("Current Resultset:", length(results$result$objectid)))

#Note: will need to make multiple calls to retreive all values if results over the limit (2000 records/call):
#This can take a while to run
offset = 2000
results.loop = data.frame(results$result)

# resp = GET(baseghgfluxUrl) - REMOVE
# respJson = fromJSON(rawToChar(resp$content))
totalCount = results$totalCount


while (offset < totalCount) {
  ghgfluxUrltemp = paste0(ghgfluxUrl, limit, "&offset=", offset) # limit is defined earlier in the script, line 53
  resp = GET(ghgfluxUrltemp)
  if (resp$status_code != 200) {
    # checks the status code of the get response. 200 is a successful response.
    print("Error: failed to retrieve exp units")
    # error message returned if the GET query is unsuccessful - could be an issue with URL, etc.
  }
  respJson = fromJSON(rawToChar(resp$content))
  print(nrow(respJson$result))
  results.df = data.frame(respJson$result)
  results.loop = rbind(results.loop, results.df)
  offset = offset + 2000 # increment offset
}


print(paste("Final Resultset:", nrow(results.loop)))

# Calculate the mean N2O_gN_ha across all sites:
meanN2O_gN_ha = mean(results.loop$N2O_gN_ha)
print(paste("Mean N2O_gN_ha across all sites:", meanN2O_gN_ha))

# write the contents to a file
setwd("C:/Users/lindsey.messinger/Desktop/") # change this path to indicate where data should be saved
write.csv(results.loop, "results.csv")
