osm-tiny-maps
=============

Download slices of OSM data and create similarly-scaled svg/png/eps graphics from the data. Based on the workflow used to creating [subways at scale](http://fakeisthenewreal.org/subway/).

This workflow is straightforward and serves my needs. You might find it useful if you want to download and process OSM data and/or edit lots of images, and think Make might be helpful. The `Makefile` is well documented, take a look.

### Install

#### OS X

Assumes you have [Make](https://www.gnu.org/software/make/), [Homebrew](http://brew.sh) and [pip](http://pip.readthedocs.org/en/stable/installing/) installed.

````
make install
````

Make can be installed (along with other useful tools) with `xcode-select --install`.

#### Other platforms

Install:
* [GDAL](http://www.gdal.org)
* [ImageMagick](http://www.imagemagick.org/script/binary-releases.php)
* [JQ](https://stedolan.github.io/jq/)
* [pip](http://pip.readthedocs.org/en/stable/installing/)

On Linux, [Make](https://www.gnu.org/software/make/) is probably already available on your system, and you will probably be able to do something like `yum/apt-get install imagemagick gdal jq`. You might have to visit the JQ site to install it.

If you're on Windows, look into [Cygwin](http://cygwin.com) 

Once those are installed, run `make install` to install SVGIS.

### Building

To build maps, you'll need two files: a bounds file and a query file. The bounds tells the `Makefile` where to download, and the query tells it what to download.

#### Bounds

The Makefile needs bounds to determine where to download, and expects a simple format that contains maximum and minimum coordinates:

````
minx: (western latitude)
miny: (southern longitude)
maxx: (eastern latitude)
maxy: (northern longitude)
````

Coordinates should be in WGS84.

The `example/` directory has an example file with boundaries around Boston and Oxford.

#### Queries

See the [Overpass Turbo](http://overpass-turbo.eu) and the [OpenStreetMap wiki](https://wiki.openstreetmap.org/wiki/Overpass_API/Language_Guide) for help in creating a query.

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

Note that the bounding box has been replaced by the `{{bbox}}` placeholder, likewise with the [verbosity](https://wiki.openstreetmap.org/wiki/Overpass_API/Language_Guide#Degree_of_verbosity). By default, `body` will be used. If you want to download OSM data that can be edited (e.g. with [JOSM](https://josm.openstreetmap.de)), run commands with `VERBOSITY=meta`. The valid verbosity levels are: `skel`, `body` and `meta` (in increasing verbosity).

#### Fun part

Once the bounds and query file are ready, save them in the same directory as the `Makefile` and add them to `conf.ini`:

````ini
QUERYFILE = my_query.ql
BOUNDSFILE = my_bounds.json
````

To make sure that everything looks right, run: `make info`. This should print something like:
````
config file: example/osm.ini
query template: example/query.ql
bounds file: example/bounds.json
bounds count: 2
available commands: qls, osms, svgs, shps, geojsons, pngs
````

Then, run one of the available commands, e.g: `make pngs`.

This will create query files, download OSM data, convert to SHP, to SVG, then to PNG or EPS, if necessary.

You may find that it's slightly faster to run `make osms && make pngs -j 4`. This will take advantage of parallel processing for the image manipulation steps. OpenStreetMap only allows one connection per IP address, so running parallel for that step doesn't work.

### Customizing

#### Different sizes

The default scale is 10, which is appropriate for a creating a small map of a neighborhood. To get larger output PNGs, use a smaller scale, and vis versa:
````
make svgs SCALE=1 # really big
make svgs SCALE=1000 # really small
````

#### Styling

`SVGIS` can style output svgs features based on their properties, but `ogr2ogr` needs to told explicitly which keys to read from the OSM file. This is controlled by the config file `osm.ini`. For instance, to include the `highway` key, often seen on roads and ways, add 'highway' to the `attributes` row in in the `[lines]` section.

The default `style.css` creates simple black line drawings. Edit it to create more elaborately styled SVGs. Use the STYLE option to use another file: `make svgs STYLE=other.css`.

Because of the limitations of how ImageMagick parses SVGs, the ID field isn't available. It is possible to use OSM attribtues to style features. For example:
````
make svgs DRAWFLAGS=--class-fields=bicycle
````

This will produce an SVG with classes like `bicycle_no` and `bicycle_permissive`. The included `style.css` includes a rule for drawing this kind of line in red. Read the [SVGIS](https://github.com/fitnr/svgis) documentation for more.

#### Projections

By default, maps are drawn in comparable Transverse Mercator projections. To use a custom projection, use pass additional options to `svgis draw`:
````bash
# New York state plane
make svgs PROJECT=EPSG:4456
# local UTM projection
make svgs PROJECT=utm
````

### License

Copyright (C) 2015, Neil Freeman. Available under the [GNU General Public License, version 3](http://www.gnu.org/licenses/gpl.html).
