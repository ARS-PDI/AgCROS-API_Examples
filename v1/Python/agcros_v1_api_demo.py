# -*- coding: utf-8 -*-
"""
AgCROS API: 
https://gpsr.ars.usda.gov/agcrospublicapi/swagger

AgCROS API v1 Demo File

Simple script showing how to extract data from the API.

@author: roger.marquez
"""
import pandas as pd;
import requests;
import sys;

apiBase = "https://gpsr.ars.usda.gov/AgCROSpublicapi/api/v1";


""" Query the experunit table """

expUnitUrl = f"{apiBase}/ExperimentalLayout/Experunits";

resp = requests.get(expUnitUrl);

if resp.status_code != 200:
    print("Error: failed to retrieve exp units");
    sys.exit();

#convert results to df to manipulate
units = pd.DataFrame(resp.json()['result']);

#get unique sites
uniqueSites = units['siteId'].unique();
print(f"Number of unique Sites: {len(uniqueSites)}")

#print first site alphabetically
uniqueSites.sort();
print(f"First site alphabetically: {uniqueSites[0]}")

# get all unitids for cofoard4
cofoard4Units = units[units['siteId'].str.contains("COFOARD4")]

""" Query a particular unit id """
selUnit = cofoard4Units['expUnitId'].iloc[0];

ghgfluxUrl = f"{apiBase}/Measurement/GreenhouseGasFlux";
ghgfluxUrl = f"{ghgfluxUrl}?expUnitId={selUnit}" # add the selected unit ID
ghgfluxUrl = f"{ghgfluxUrl}&limit=2000" # add query limit

resp = requests.get(ghgfluxUrl);

if resp.status_code != 200:
    print("Error: failed to retrieve exp units");
    sys.exit();

results = pd.DataFrame(resp.json()['result']);

# num of results
print(f"Num Records for {selUnit}: {len(results)}");


""" Query all units for the indicated site """

# treatment/units need to be explicitly called: expUnitId=exp1&expUnitId=exp2...

baseghgfluxUrl = f"{apiBase}/Measurement/GreenhouseGasFlux?";
for exp in cofoard4Units['expUnitId']:
    baseghgfluxUrl = f"{baseghgfluxUrl}expUnitId={exp}&" # add the selected unit ID
ghgfluxUrl = f"{baseghgfluxUrl}limit=2000" # add query limit

resp = requests.get(ghgfluxUrl);

if resp.status_code != 200:
    print("Error: failed to retrieve gfgflux");
    sys.exit();

# can see how many results are here:
respJson = resp.json();
results = pd.DataFrame(resp.json()['result']);

print(f"Total # of results: {respJson['totalCount']}");
print(f"Returned # of results: {respJson['resultCount']}");
print(f"Current Resultset: {len(results)}");

#Note: will need to make multiple calls to retreive all values if results over the limit (2000 records/call):
# This can take a while to run.
totalCount = respJson['totalCount'];
offset = 2000;
while offset < totalCount:
    ghgfluxUrl = f"{baseghgfluxUrl}limit=2000&offset={offset}" # add query limit 
    resp = requests.get(ghgfluxUrl);
    if resp.status_code != 200:
        print("Error: failed to retrieve exp units");
        sys.exit();
    respJson = resp.json();
    results = results.append(resp.json()['result'], ignore_index=True);
    #increment offset:
    offset = offset + 2000;

print(f"Final Resultset: {len(results)}");
# calculate the mean N2O_gN_ha across all sites:

mean = results['N2O_gN_ha'].mean();
print(f"Mean N2O_gN_ha aross all sites: {mean}")

# write the contents to a file

results.to_csv("results.csv", index=False);




