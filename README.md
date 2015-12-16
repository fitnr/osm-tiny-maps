osm-tiny-maps
=============

Download slices of OSM data and create similarly-scaled svg/png/eps graphics from the data.

## Installing

### OS X

Assumes you have [Make](https://www.gnu.org/software/make/), [Homebrew](http://brew.sh), [pip](http://pip.readthedocs.org/en/stable/installing/) and [virtualenv](https://github.com/pypa/virtualenv) installed. Make is installed alongside the XCode developer tools (install with `xcode-select --install`).

````
make install
````

### Other platforms

Install [GDAL](http://www.gdal.org), [ImageMagick](http://www.imagemagick.org/script/binary-releases.php), [JQ](https://stedolan.github.io/jq/). On Linux, you will probably be able to do something like `yum/apt-get install imagemagick gdal`.

Assuming [pip](http://pip.readthedocs.org/en/stable/installing/) and [virtualenv](https://github.com/pypa/virtualenv) are installed:
````
make .env/activate
. .env/activate
pip install -r requirements.txt
````

## Creating a bounds file

The Makefile needs bounds to determine where to download, and expects a simple format that contains maximum and minimum coordinates:

````
minx: (western latitude)
miny: (southern longitude)
maxx: (eastern latitude)
maxy: (northern longitude)
````

Coordinates should be in WGS84.

The `example/` directory has an example file with boundaries around Boston and Oxford.

## Creating a query

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

Note that the bounding box has been replaced by the `{{bbox}}` placeholder, likewise with the [verbosity](https://wiki.openstreetmap.org/wiki/Overpass_API/Language_Guide#Degree_of_verbosity). By default, `skel` will be used. If you want to download OSM data that can be edited (e.g. with [JOSM](https://josm.openstreetmap.de)), you can run commands with `VERBOSITY=meta` or `VERBOSITY=body`. Complete list of verbosity levels: ids, body, skel, tags, meta.

## Creating images

Once the bounds and query file are ready, save them in the same directory as the `Makefile` and add them to `conf.ini`:

````ini
QUERYFILE = my_query.ql
BOUNDSFILE = my_bounds.json
````

To make sure that everything looks right, run: `make info`. This should print something like:
````
config file: ini/osm.ini
query template: query.ql
bounds file: bounds.json
bounds count: 140
available commands: qls, osms, svgs, shps, geojsons, pngs
````

Then, run one of:
```
make pngs
make epss
make svgs
```

This will create query files, download data, convert to SHP, to SVG, then to PNG or EPS, if necessary.

You may find that it's slightly faster to run `make osms && make pngs -j 4`. This will take advantage of parallel processing for the image manipulation steps. OpenStreetMap only allows one connection per IP address, so running parallel for that step won't work.

## Different sizes

The default scale is 10, which is appropriate for a creating a small map of a neighborhood. To get larger output PNGs, use a smaller scale, and vis versa:
````
make svgs SCALE=1 # really big
make svgs SCALE=1000 # really small
````

## Adding style

`SVGIS` can style output svgs features based on their properties, but `ogr2ogr` needs to told explicitly which keys to read from the OSM file. This is controlled by the config file `osm.ini`. For instance, to include the `highway` key, often seen on roads and ways, add 'highway' to the `attributes` row in in the `[lines]` section.

The default `style.css` creates simple black line drawings. Edit it to create more elaborately styled SVGs. Use the STYLE option to use another file: `make svgs STYLE=other.css`.

Because of the limitations of how ImageMagick parses SVGs, the ID field isn't available. It is possible to use OSM attribtues to style features. For example:
````
make svgs DRAWFLAGS=--class-fields=bicycle
````

This will produce an SVG with classes like `bicycle_no` and `bicycle_permissive`. The included `style.css` includes a rule for drawing this kind of line in red. Read the [SVGIS](https://github.com/fitnr/svgis) documentation for more.

## License

Copyright (C) 2015, Neil Freeman. Available under the [GNU General Public License, version 3](http://www.gnu.org/licenses/gpl.html).