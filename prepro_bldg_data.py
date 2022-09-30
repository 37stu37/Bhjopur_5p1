import geopandas as gpd
from pathlib import Path

server = Path("Y://_TEMP//Server_Gitdata")

b = gpd.read_file(server / "Bhojpur_Mw5.1\shapefile\bldgs_preprocs_E4.shp")
d = gpd.read_file(server / "Bhojpur_Mw5.1\shapefile\Nepal_Districts_v2020_UTM45shp.shp")

# create centroid to prevent overlap of polygons
c = b.centroids

# merge building with districts
c_d = c.sjoin(d)

# export shapefile
c_d = gpd.to_file(server / "Bhojpur_Mw5.1\shapefile\bldgs_preprocs_E4_DISTRICTS.shp")
