osm-tiny-maps
=============

Download slices of OSM data and create similarly-scaled maps in svg/png/eps format from the data.

This workflow is based on the workflow used to creating [subways at scale](http://fakeisthenewreal.org/subway/). I've generalized it it to serve as a template for others with the same problem: drawing OSM for many parts of the world into similar maps. 

The workflow uses make, which is an ancient but rock-solid tool for processing files. The `Makefile` is well documented, take a look.

### Install

#### OS X

Check that you have [Make](https://www.gnu.org/software/make/), [Homebrew](http://brew.sh) and [pip](http://pip.readthedocs.org/en/stable/installing/) installed, then run:

````
make install
````

Make can be installed (along with other useful tools) with `xcode-select --install`.

#### Other platforms

Install:
* [GDAL](http://www.gdal.org)
* [ImageMagick](http://www.imagemagick.org/script/binary-releases.php)
* [pip](http://pip.readthedocs.org/en/stable/installing/)

On Linux, [Make](https://www.gnu.org/software/make/) is likely already available. To install the prerequisites, do something like `yum/apt-get install imagemagick libgdal1-dev gdal-bin`.

If you're on Windows, look into [Cygwin](http://cygwin.com) to provide a bash shell, and [OSGeo4W](https://trac.osgeo.org/osgeo4w/) for providing GDAL.

Once those are installed, run `make install` to install SVGIS, the map-drawing tool. Check if the prerequisites are set to go with `make ready`.

### Building

To build maps, you'll need to create files to tell the workflow what to do:
* a bounds file tells the `Makefile` where to download
* a query file tells it what to download
* A css file tells it how to style the maps

Set the locations of these files by editing `config.ini`.

#### Bounds

The Makefile needs bounds to determine where to download. It reads a simple CSV file that contains place names and bounding box coordinates:

````
placename,minx,miny,maxx,maxy
placename,(western latitude),(southern longitude),(eastern latitude),(northern longitude)
````

This file shouldn't have a header row. Coordinates should be in WGS84.

The `example/` directory has an example file with boundaries around Boston, Oxford and Chicago's Loop.

Place names must not contain commas, spaces, colons, slashes or quotes (`, :\/'"`), nor the words `lines`, `points` or `multipolygons`.

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

#### Styles

Editing the map styles, requires a basic understanding of [CSS](https://developer.mozilla.org/en-US/docs/Web/CSS). Styling SVGs is exactly like styling HTML, but instead of `div` and `a` elements, there are `g` and `polygon` elements. To get an idea of how it works, start by picking a layer and adding a style rule for all of the elements it contains, e.g.:

````css
/* Add a huge red stroke on lines in the boston SVG */
#bostonlines * {
	stroke: red;
	stroke-width: 5px;
}
````

Next, you might change all elements:
````csss
/* Make all polygons blue */
polygon {
	fill: blue;
}
````

Like HTML, the best way to fiddle with this is to look at the source. Open the SVG in your favorite web browser and poke around with the Web Inspector.

`SVGIS` can style output svgs features based on their properties, but `ogr2ogr` needs to told explicitly which keys to read from the OSM file. This is controlled by the config file `osm.ini`. For instance, to include the `highway` key, often seen on roads, add 'highway' to the `attributes` key in the `[lines]` section.

To let `svgis` know which fields to add to the SVG, provide an argument for `svgis`'s `--class-fields` option:
````
make svgs CLASSFIELDS="surface,leisure"
...
svgis draw ... --class-fields surface,leisure ...
````

With this option set, the styles in `example/style.css` will create simple maps with asphalt bike paths in blue and parks in green. Edit the `STYLEFILE` option in `config.ini` to use your own file, and use different class-fields to create more elaborately styled maps. Read the [svgis](https://github.com/fitnr/svgis) documentation for details on styling.

#### Fun part

Once the bounds, query template and css files are ready, save them in the same directory as the `Makefile` and add them to `conf.ini`:

````ini
QUERYFILE = my_query.ql
BOUNDSFILE = my_bounds.csv
STYLEFILE = my_styles.css
````

To make sure that everything looks right, run: `make info`. This should print something like:
````
query template: my_query.ql
bounds file: my_bounds.csv
css file: my_styles.css
osm conversion settings: osm.ini
bounds count: 42
available commands: qls, osms, svgs, geojsons, pngs
````

Then run one of the available commands, e.g: `make pngs`.

This will create query files, download OSM data, convert to GeoJSON, to SVG, then to PNG or EPS, if necessary.

You may find that it's faster to run `make osms && make pngs -j 3`. This will take advantage of parallel processing for the image manipulation steps. OpenStreetMap only allows one connection per IP address, so running parallel for that step doesn't work.

### Customizing

The `Makefile` is intended to be edited and adapted. There are some built in ways to customize the output, but first let's clear up how it works.

The tools used are:

* bash builtins format the template query, converting each line of the `bounds.csv` file into a `.ql` query
* `curl`, the standard builtin file downloader, uses the `.ql` to download OSM data from the Overpass API
* `ogr2ogr` converts the OSM data into GeoJSON, a standard geodata format
* `svgis` draws the geojson files as SVGs
* `convert`, part of ImageMagick, converts the SVGs into EPS or PNG files

Stated another way:
````
bounds.csv -> .ql (bash creates queries)
.ql -> .osm (curl downloads from OSM)
.osm -> .geojson (ogr2ogr converts)
.geojson -> .svg (svgis draws)
.svg -> .png/.eps (ImageMagick converts)
````
 
You'll find the docs for the different tools useful:

* [OpenStreetMap](http://wiki.openstreetmap.org/wiki/Main_Page)
* [overpass api](http://wiki.openstreetmap.org/wiki/Overpass_API)
* [ogr2ogr](http://www.gdal.org/ogr2ogr.html)
* [svgis](http://pythonhosted.org/svgis/)
* [ImageMagick convert](http://imagemagick.org/script/convert.php)

#### Geometries

OpenStreetMap geometries come in three flavors: `points`, `lines`, and `multipolygons` (This is a [gross over-simplification](http://wiki.openstreetmap.org/wiki/Elements)). By default, osm-tiny-maps processes lines and multipolygons. To change this, use the `GEOMETRY` variable:

```bash
# process only multipolygons
make svgs GEOMETRY='multipolygons'
# process points, lines and multipolygons
make pngs GEOMETRY='points lines multipolygons'
````

#### Map scale

Map scale in SVGIS is the ratio between svg units and projection units. Most map projections use meters or feet, and svg clients usually represent an svg units as a pixel or a fraction of an inch.

The default scale is 10, which is appropriate for a creating a small map of a neighborhood. To get larger output PNGs, use a smaller scale, and vis versa:
````bash
# really big
make svgs SCALE=1 
# really small
make svgs SCALE=1000
````

#### Map projections

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
