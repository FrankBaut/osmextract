
<!-- README.md is generated from README.Rmd. Please edit that file -->

# geofabric

<!-- badges: start -->

[![Travis build
status](https://travis-ci.org/itsleeds/geofabric.svg?branch=master)](https://travis-ci.org/itsleeds/geofabric)
<!-- badges: end -->

The goal of geofabric is to make it easier for open source software
users to access freely available, community created geographic data, in
the form of OpenSteetMap data shipped by [Geofabrik
GmbH](http://download.geofabrik.de).

## Installation

<!-- You can install the released version of geofabric from [CRAN](https://CRAN.R-project.org) with: -->

<!-- ``` r -->

<!-- install.packages("geofabric") -->

<!-- ``` -->

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("ITSLeeds/geofabric")
```

## Usage

Give geofabric the name of a geofabric zone and it will download and
import it. By default it imports the ‘lines’ layer, but any layer can be
read-in. Behind the scenes, the function `read_pbf()`, a wrapper around
`sf::st_read()` is used with configuration options to import additional
columns from the .pbf files not imported by default, including
`maxspeed`, `lanes` and `oneway` (the attributes to include can be set
with `attributes` argument):

``` r
library(geofabric)
andorra_lines = get_geofabric(name = "andorra", layer = "lines")
#> No exact matching geofabric zone. Best match is Andorra (1.5 MB)
#> Downloading http://download.geofabrik.de/europe/andorra-latest.osm.pbf to 
#> /tmp/Rtmp3TDgSG/andorra.osm.pbf
#> Old attributes: attributes=name,highway,waterway,aerialway,barrier,man_made
#> New attributes: attributes=name,highway,waterway,aerialway,barrier,man_made,maxspeed,oneway,building,surface,landuse,natural,start_date,wall,service,lanes,layer,tracktype,bridge,foot,bicycle,lit,railway,footway
#> Using ini file that can can be edited with file.edit(/tmp/Rtmp3TDgSG/ini_new.ini)
names(andorra_lines)
#>  [1] "osm_id"     "name"       "highway"    "waterway"   "aerialway" 
#>  [6] "barrier"    "man_made"   "maxspeed"   "oneway"     "building"  
#> [11] "surface"    "landuse"    "natural"    "start_date" "wall"      
#> [16] "service"    "lanes"      "layer"      "tracktype"  "bridge"    
#> [21] "foot"       "bicycle"    "lit"        "railway"    "footway"   
#> [26] "z_order"    "other_tags" "geometry"
andorra_point = get_geofabric(name = "andorra", layer = "points", attributes = "shop")
#> No exact matching geofabric zone. Best match is Andorra (1.5 MB)
#> Data already detected in /tmp/Rtmp3TDgSG/andorra.osm.pbf
#> Old attributes: attributes=name,barrier,highway,ref,address,is_in,place,man_made
#> New attributes: attributes=name,barrier,highway,ref,address,is_in,place,man_made,shop
#> Using ini file that can can be edited with file.edit(/tmp/Rtmp3TDgSG/ini_new.ini)
names(andorra_point) # note the 'shop' column has been added
#>  [1] "osm_id"     "name"       "barrier"    "highway"    "ref"       
#>  [6] "address"    "is_in"      "place"      "man_made"   "shop"      
#> [11] "other_tags" "geometry"
plot(andorra_lines$geometry)
plot(andorra_point[andorra_point$shop == "supermarket", ], col = "red", add = TRUE)
#> Warning in plot.sf(andorra_point[andorra_point$shop == "supermarket", ], :
#> ignoring all but the first attribute
```

<img src="man/figures/README-example-1.png" width="100%" />

The above code plotted lines representing roads and other linear
features in Andorra, with an overlay of shops that are represented in
OSM data. If there are no files available for a zone name, geofabric
will search for and import the nearest matching zone:

``` r
iow_lines = get_geofabric(name = "isle wight")
#> No exact matching geofabric zone. Best match is Isle of Wight (7.2 MB)
#> Downloading http://download.geofabrik.de/europe/great-britain/england/isle-of-wight-latest.osm.pbf to 
#> /tmp/Rtmp3TDgSG/isle wight.osm.pbf
#> Old attributes: attributes=name,highway,waterway,aerialway,barrier,man_made
#> New attributes: attributes=name,highway,waterway,aerialway,barrier,man_made,maxspeed,oneway,building,surface,landuse,natural,start_date,wall,service,lanes,layer,tracktype,bridge,foot,bicycle,lit,railway,footway
#> Using ini file that can can be edited with file.edit(/tmp/Rtmp3TDgSG/ini_new.ini)
iow_file = file.path(tempdir(), "isle wight.osm.pbf")
plot(iow_lines$geometry) # note the lines contain ferry services to france and elsewhere
```

<img src="man/figures/README-matching-1.png" width="100%" />

Take care: files downloaded from geofabrik can be large.

If you want to use `st_read()` to read-in the .pbf files, e.g. to set
additional query arguments, you can do so, as demonstrated
below.

``` r
query = "select highway from lines where highway = 'cycleway' or highway = 'residential'"
iow_lines_subset = sf::st_read(iow_file, layer = "lines", query = query)
#> Reading layer `lines' from data source `/tmp/Rtmp3TDgSG/isle wight.osm.pbf' using driver `OSM'
#> Simple feature collection with 2537 features and 1 field
#> geometry type:  LINESTRING
#> dimension:      XY
#> bbox:           xmin: -1.549514 ymin: 50.57872 xmax: -1.072414 ymax: 50.76727
#> epsg (SRID):    4326
#> proj4string:    +proj=longlat +datum=WGS84 +no_defs
plot(iow_lines_subset)
```

<img src="man/figures/README-query-1.png" width="100%" />

# geofabrik zones

The package ships with a data frame representing all zones made
available by the package. These can be interactively searched with the
following command:

``` r
View(sf::st_drop_geometry(geofabric_zones[1:3]))
```

That will display the following table in the
viewer:

| name                  | size\_pbf | pbf\_url                                                        |
| :-------------------- | :-------- | :-------------------------------------------------------------- |
| Africa                | (3.2 GB)  | <http://download.geofabrik.de/africa-latest.osm.pbf>            |
| Antarctica            | (29.0 MB) | <http://download.geofabrik.de/antarctica-latest.osm.pbf>        |
| Asia                  | (7.3 GB)  | <http://download.geofabrik.de/asia-latest.osm.pbf>              |
| Australia and Oceania | (684 MB)  | <http://download.geofabrik.de/australia-oceania-latest.osm.pbf> |

The following attributes are available from this file if you want more
info about each geofabric zone:

``` r
names(geofabric_zones)
#>  [1] "name"         "size_pbf"     "pbf_url"      "page_url"    
#>  [5] "part_of"      "level"        "continent"    "country"     
#>  [9] "region"       "subregion"    "geometry_url" "geometry"
```

Each geographic level (continents, countries, regions and subregions) is
shown in the map below, with a few of them named for reference.

``` r
# todo: tidy up geofabric_zones data and this code chunk
library(tmap)
sel1 = is.na(geofabric_zones$level)
geofabric_zones$level[sel1] = 1
geofabric_zones$label = ""
geofabric_zones$label[sel1] = geofabric_zones$name[sel1]
set.seed(9)
sel2 = sample(x = 1:nrow(geofabric_zones), size = 5)
geofabric_zones$label[sel2] = geofabric_zones$name[sel2]
tm_shape(geofabric_zones) +
  tm_polygons() +
  tm_text(text = "label") +
  tm_facets(by = "level")
#> Warning: The shape geofabric_zones is invalid. See sf::st_is_valid
#> Linking to GEOS 3.7.1, GDAL 2.4.2, PROJ 5.2.0
```

<img src="man/figures/README-zonemap-1.png" width="100%" />

A couple of the countries, regions and sub regions available is shown
below.

``` r
geofabric_countries = geofabric_zones[geofabric_zones$level == 2, ]
knitr::kable(sf::st_drop_geometry(geofabric_countries[1:2, 1:3]))
```

|    | name    | size\_pbf    | pbf\_url                                                     |
| -- | :------ | :----------- | :----------------------------------------------------------- |
| 9  | Algeria | \[.osm.bz2\] | <http://download.geofabrik.de/africa/algeria-latest.osm.pbf> |
| 10 | Angola  | \[.osm.bz2\] | <http://download.geofabrik.de/africa/angola-latest.osm.pbf>  |

``` r
geofabric_regions = geofabric_zones[geofabric_zones$level == 3, ]
knitr::kable(sf::st_drop_geometry(geofabric_regions[1:2, 1:3]))
```

|     | name           | size\_pbf | pbf\_url                                                         |
| --- | :------------- | :-------- | :--------------------------------------------------------------- |
| 238 | Chūbu region   | (276 MB)  | <http://download.geofabrik.de/asia/japan/chubu-latest.osm.pbf>   |
| 239 | Chūgoku region | (128 MB)  | <http://download.geofabrik.de/asia/japan/chugoku-latest.osm.pbf> |

``` r
geofabric_subregions = geofabric_zones[geofabric_zones$level == 4, ]
knitr::kable(sf::st_drop_geometry(geofabric_subregions[1:2, 1:3]))
```

|     | name                       | size\_pbf | pbf\_url                                                                                         |
| --- | :------------------------- | :-------- | :----------------------------------------------------------------------------------------------- |
| 360 | Regierungsbezirk Freiburg  | (111 MB)  | <http://download.geofabrik.de/europe/germany/baden-wuerttemberg/freiburg-regbez-latest.osm.pbf>  |
| 361 | Regierungsbezirk Karlsruhe | (104 MB)  | <http://download.geofabrik.de/europe/germany/baden-wuerttemberg/karlsruhe-regbez-latest.osm.pbf> |