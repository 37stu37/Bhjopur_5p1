import geopandas as gpd
import pandas as pd
from pathlib import Path

# server = Path("Y://_TEMP//Server_Gitdata")
server = Path("/Volumes/Nepal/SajagNepal/003_GIS_data/_TEMP/Server_Gitdata")

# using buildings
s = gpd.read_file(server / "Bhojpur_Mw5.1" / "OQruns" / "OQrun" / "sites.shp")

# create sites for OQ
d = {'lat': s.y, 'lon': s.x}
df = pd.DataFrame(data=d)
df = df.drop_duplicates(keep='first')

# write to csv
df.to_csv(server / "Bhojpur_Mw5.1" / "OQruns" / "sites.csv", header=False, index=False)

# using slope units
b = gpd.read_file(server / "Bhojpur_Mw5.1" / "shapefile" / "bldgs_preprocs_E4.shp")
d = gpd.read_file(server / "Bhojpur_Mw5.1" / "shapefile" / "Nepal_Districts_v2020_UTM45shp.shp")

# create centroid to prevent overlap of polygons
c = b.centroids

# merge building with districts
c_d = c.sjoin(d)

# export shapefile
c_d = gpd.to_file(server / "Bhojpur_Mw5.1" / "shapefile" / "bldgs_preprocs_E4_DISTRICTS.shp")
