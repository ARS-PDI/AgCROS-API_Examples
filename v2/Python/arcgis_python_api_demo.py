"""
ArcGIS Python API Demo File

A short Jupyter Notebook showing how to query data from ArcGIS servers.

ArcGIS API for Python Reference: https://developers.arcgis.com/python/api-reference/index.html

Author: Josh Birlingmair
"""

import os
from arcgis.features import FeatureLayerCollection

# The API allows you to list all of the feature layers for a location
ftr_lyrs = FeatureLayerCollection(
    'https://pdihosting.azurecloudgov.us/arcgis/rest/services/AgCROS/COFOARD4/FeatureServer')
ftr_lyrs.layers

# Find the table called "MetaUnits_Unit"
i = 0

for ftr_lyr in ftr_lyrs.layers:
    if ftr_lyr.properties.name == 'MetaUnits_Unit':
        break

    i += 1

# Display the number of records
ftr_lyr = ftr_lyrs.layers[i]
num_records = ftr_lyr.query(where='1=1', return_count_only=True)
num_records

# Display the first record's Unit ID
records = ftr_lyr.query(where='1=1')
records.features[0].attributes['unit_id']

# Display the 5 records only (as a Spacial DataFrame). `return_all_records` must be set to False
# to set the record count
records = ftr_lyr.query(where='1=1', return_geometry=False,
                        return_all_records=False, result_record_count=5)
records.sdf

# Find the measurement or management layer with the most records, query it, and display it
index = max_records_index = 0
max_num_records = 0

for ftr_lyr in ftr_lyrs.layers:
    if ftr_lyr.properties.name.startswith('Meas') or ftr_lyr.properties.name.startswith('Mgt'):
        num_records = ftr_lyr.query(where='1=1', return_count_only=True)

        if num_records > max_num_records:
            max_num_records = num_records
            max_records_index = index

    index += 1

ftr_lyr = ftr_lyrs.layers[max_records_index]
records = ftr_lyr.query(where='1=1', return_geometry=False)
records.sdf

# Query a subset of the records of the layer `MeasGHGFlux_Unit` (the layer with the most records)
# and save it to file
records_df = ftr_lyr.query(where='1=1', return_geometry=False,
                           return_all_records=False, result_record_count=2000, as_df=True)
csv_path = os.path.join(r'C:\Users\Public\Downloads',
                        f'{ftr_lyr.properties.name}_subset.csv')
records_df.to_csv(csv_path, index=False)

# Export the full set of records as a CSV
records_df = ftr_lyr.query(where='1=1', return_geometry=False, as_df=True)
csv_path = os.path.join(r'C:\Users\Public\Downloads',
                        f'{ftr_lyr.properties.name}.csv')
records_df.to_csv(csv_path, index=False)

# Calculate basic statistics using the DataFrame
mean = records_df['co2_gc_ha_d'].mean()
print('Mean:', mean)

median = records_df['co2_gc_ha_d'].median()
print('Median:', median)
