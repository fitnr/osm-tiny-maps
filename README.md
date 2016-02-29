osm-tiny-maps
=============

Download slices of OSM data and create similarly-scaled svg/png/eps graphics from the data. Based on the workflow used to creating [subways at scale](http://fakeisthenewreal.org/subway/).

This workflow is straightforward and serves my needs. You might find it useful if you want to download and process OSM data and/or edit lots of images, and think Make might be helpful. The `Makefile` is well documented, take a look.

### Install

#### OS X

Assuming you have [Make](https://www.gnu.org/software/make/), [Homebrew](http://brew.sh) and [pip](http://pip.readthedocs.org/en/stable/installing/) installed, run:

````
make install
````

Make can be installed (along with other useful tools) with `xcode-select --install`.

#### Other platforms

Install:
* [GDAL](http://www.gdal.org)
* [ImageMagick](http://www.imagemagick.org/script/binary-releases.php)
* [pip](http://pip.readthedocs.org/en/stable/installing/)

On Linux, [Make](https://www.gnu.org/software/make/) is probably already available on your system, and you likely be able to do something like `yum/apt-get install imagemagick libgdal1-dev gdal-bin`.

If you're on Windows, look into [Cygwin](http://cygwin.com), to provide a bash shell, and [OSGeo4W](https://trac.osgeo.org/osgeo4w/) for providing GDAL.

Once those are installed, run `make install` to install SVGIS. Run `make ready` to check if all the prerequisites are available.

### Building

To build maps, you'll need two files: a bounds file and a query file. The bounds tells the `Makefile` where to download, and the query tells it what to download.

Once the bounds and query are ready, maps are drawn with the following steps:
````
.ql  -> .osm (curl downloads from OSM)
.osm -> .geojson (ogr2ogr converts)
.geojson -> .svg (svgis draws)
.svg -> .png/.eps (ImageMagick converts)
````

#### Bounds

The Makefile needs bounds to determine where to download. It reads a simple CSV file that contains place names and bounding box coordinates:

````
placename,minx,miny,maxx,maxy
placename,(western latitude),(southern longitude),(eastern latitude),(northern longitude)
````

This file shouldn't have a header row. Coordinates should be in WGS84.

The `example/` directory has an example file with boundaries around Boston, Oxford and Chicago's Loop.

Place names must not contain spaces, commas or quotes (`,'" `). It will be used to name files, so avoid colons and slashes, too (`:\/`).

#### Queries

OSM Overpass queries use a unique and fairly complicated syntax, See [Overpass Turbo](http://overpass-turbo.eu) and the [Overpass API language guide](https://wiki.openstreetmap.org/wiki/Overpass_API/Language_Guide) for help in writing a query.

The example directory has a simple query that downloads pedestrian paths:
````
[out:xml][timeout:60];
(
    way[highway=footway]({{bbox}});
);
out body;
>;
out {{verbosity}} qt;
````

Note the `{{bbox}}` and [`{{verbosity}}`](https://wiki.openstreetmap.org/wiki/Overpass_API/Language_Guide#Degree_of_verbosity) placeholders. If you want to download OSM data that can be edited (e.g. with [JOSM](https://josm.openstreetmap.de)), run commands with `VERBOSITY=meta`. The valid verbosity levels are: `skel`, `body` and `meta` (in increasing verbosity), the default is body.

#### Fun part

Once the bounds and query file are ready, save them in the same directory as the `Makefile` and add them to `conf.ini`:

````ini
QUERYFILE = my_query.ql
BOUNDSFILE = my_bounds.csv
````

To make sure that everything looks right, run: `make info`. This should print something like:
````
config file: example/osm.ini
query template: example/query.ql
bounds file: example/bounds.csv
bounds count: 2
available commands: qls, osms, svgs, geojsons, pngs
````

Then, run one of the available commands, e.g: `make pngs`.

This will create query files, download OSM data, convert to GeoJSON, to SVG, then to PNG or EPS, if necessary.

You may find that it's slightly faster to run `make osms && make pngs -j 4`. This will take advantage of parallel processing for the image manipulation steps. OpenStreetMap only allows one connection per IP address, so running parallel for that step doesn't work.

### Customizing

This Makefile is intended to be edited and adapted. You'll probably find the docs for the different tools employed here useful:
* [OpenStreetMap](http://wiki.openstreetmap.org/wiki/Main_Page)
* [overpass api](http://wiki.openstreetmap.org/wiki/Overpass_API)
* [ogr2ogr](http://www.gdal.org/ogr2ogr.html)
* [svgis](http://pythonhosted.org/svgis/)
* [ImageMagick convert](http://imagemagick.org/script/convert.php)

Here are a few built-in ways to change the results:

#### Geometries

OpenStreetMap geometries come in three flavors: `points`, `lines`, and `multipolygons` (This is a [gross over-simplification](http://wiki.openstreetmap.org/wiki/Elements)). By default, osm-tiny-maps processes lines and multipolygons. To change this, use the `GEOMETRY` variable:

```bash
# process only multipolygons
make svgs GEOMETRY='multipolygons'
# process points, lines and multipolygons
make pngs GEOMETRY='points lines multipolygons'
````

#### Different sizes

Map scale in SVGIS is the ratio between svg units and projection units. Most map projections use meters or feet, and svg clients usually represent an svg units as a pixel or a fraction of an inch.

The default scale is 10, which is appropriate for a creating a small map of a neighborhood. To get larger output PNGs, use a smaller scale, and vis versa:
````
make svgs SCALE=1 # really big
make svgs SCALE=1000 # really small
````

#### Styling

`SVGIS` can style output svgs features based on their properties, but `ogr2ogr` needs to told explicitly which keys to read from the OSM file. This is controlled by the config file `osm.ini`. For instance, to include the `highway` key, often seen on roads and ways, add 'highway' to the `attributes` row in in the `[lines]` section.

It is possible to use OSM attributes to style features. To do so, you must provide an argument for the svgis draw `--class-fields` option:
````
make svgs CLASSFIELDS="surface,leisure"
````

With this option set, the styles in `example/style.css` will create simple drawings of asphalt bike paths in blue and parks in green. Edit the STYLEFILE option in `config.ini` to use your own file, and use different class-fields to create more elaborately styled maps. Read the [SVGIS](https://github.com/fitnr/svgis) documentation for more. 

#### Projections

By default, maps are drawn in comparable Transverse Mercator projections. To use a custom projection, use pass additional options to `svgis draw`:
````bash
# Use the local UTM projection
make svgs PROJECT=utm
# Use New York state plane
make svgs PROJECT=EPSG:4456
````

The `EPSG:4446` in the second example is a map projection ID. The websites [espg.io](http://espg.io) and [spatialreference.org](http://spatialreference.org/ref/epsg/) are a good references for finding the EPSG codes.

### License

Copyright (C) 2015, Neil Freeman. Available under the [GNU General Public License, version 3](http://www.gnu.org/licenses/gpl.html).
