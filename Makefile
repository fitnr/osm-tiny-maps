# osm-tiny-maps, OpenStreetMap downloads and image-creation
# Copyright (C) 2015, Neil Freeman

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Useful for downloading another iteration of similar data
# setting this will put all files in the named folder
PREFIX = .

# INI files are valid Make variable declarations
include config.ini 

# Overpass API endpoint
API ?= http://overpass-api.de/api/interpreter
CURLFLAGS = -s

# List of bounding boxes to target for download
LOCATIONS = $(shell $(JQ) keys[] $(BOUNDSFILE))

# OSM verbosity
# valid options: skel, body, meta
VERBOSITY ?= body

# default configuration file for ogr2ogr
OSM_CONFIG_FILE ?= osm.ini
OSM_USE_CUSTOM_INDEXING = NO
export OSM_CONFIG_FILE OSM_USE_CUSTOM_INDEXING
OGRFLAGS = -lco ENCODING=UTF-8

# shorthands for executables

JQ = jq --raw-output
CONVERT = convert
SVGIS = svgis

# list of png files to generate,
# based on the keys of the bounding box
PNGS = $(addsuffix .png,$(addprefix $(PREFIX)/png/,$(LOCATIONS)))

# imagemagick flags for adding small border
DENSITY = 144
BORDER = 10
REPAGEFLAGS = -trim +repage
BORDERFLAGS = -bordercolor white -border $(BORDER)x$(BORDER)

# svgis draw flags
SCALE = 10
# Better compatibility for Adobe Illustrator
DRAWFLAGS = --no-viewbox --inline
# generate a local transverse-mercator projection
PROJECTION = local

# Slightly-too-clever declaration of folders and shorthand tasks
FILETYPES = ql osm svg shp geojson eps png
DIRS = $(addprefix $(PREFIX)/,$(FILETYPES))
TASKS = $(addsuffix s,$(FILETYPES))

# These don't create literal files
.PHONY: info install ready clean $(TASKS)

info:
	@echo config file: $(OSM_CONFIG_FILE)
	@echo query template: $(QUERYFILE)
	@echo bounds file: $(BOUNDSFILE)
	@echo bounds count: $(words $(LOCATIONS))
	@echo available commands: $(TASKS)

# Shorthand tasks
# pngs is easy, because we have a list of files
pngs: $(PNGS)

# Other rules require a second expansion to state simply
# Without ".SECONDEXPANSION" this would yield a file ending in .%
.SECONDEXPANSION:
qls osms epss shps geojsons svgs: %s: $(foreach x,$(LOCATIONS),$(PREFIX)/%/$x.$$*)

# file creation tasks in reverse-chronological order
#

# Generate a png from a svg.
# the order-only prerequisite ("| PREFIX/png") doesn't check the folder timestamp
$(PREFIX)/png/%.png: $(PREFIX)/svg/%.svg | $(PREFIX)/png
	$(CONVERT) $< -density $(DENSITY) $(REPAGEFLAGS) $(BORDERFLAGS) $@

# Generate an EPS from a SVG
$(PREFIX)/eps/%.eps: $(PREFIX)/svg/%.svg | $(PREFIX)/eps
	$(CONVERT) $< $(REPAGEFLAGS) $@

# Default geo format, could be geojson
GEO = shp
FMT.geojson = GeoJSON
FMT.shp = "ESRI Shapefile"

# Draw the svg with SVGIS, using whichever GEO format is set
$(PREFIX)/svg/%.svg: $(PREFIX)/$(GEO)/%.$(GEO) $(STYLEFILE) | $(PREFIX)/svg
	$(SVGIS) draw --crs $(PROJECTION) --padding 10 --scale $(SCALE) --style $(STYLEFILE) $(DRAWFLAGS) $< -o $@

# General task for creating either a shp or a geojson.
# The nested variable is sort of like an array, 
# lets us check the appropriate format name, which doesn't easily map from the file suffix. 
$(PREFIX)/shp/%.shp $(PREFIX)/geojson/%.geojson: $(PREFIX)/osm/%.osm | $$(@D)
	@rm -f $@
	ogr2ogr -f $(FMT$(suffix $@)) $(OGRFLAGS) $@ $^ lines

# OSM files are precious because they tend to be big,
# we don't want to delete them and have to redownload
.PRECIOUS: osm/%.osm
# Post the query to the OSM api.
$(PREFIX)/osm/%.osm: $(PREFIX)/ql/%.ql | $(PREFIX)/osm
	curl $(API) $(CURLFLAGS) -o $@ --data @$<

# Read bounding box from the bounds file, use sed to do some quick templating on the query file
$(PREFIX)/ql/%.ql: bounds.txt | $(PREFIX)/ql
	read BBOX <<<$$(fgrep '$*' $< | cut -d '|' -f 2); \
	sed -e "s/{{bbox}}/$${BBOX}/g;s/{{verbosity}}/$(VERBOSITY)/g;s,//.*,," $(QUERYFILE) | \
	tr '\n' ' ' | \
	sed -e 's,/\*.*\*/,,g' > $@

bounds.txt: $(BOUNDSFILE)
	$(JQ) 'to_entries[] | [.key, (.value | [.miny, .minx, .maxy, .maxx] | map(tostring) | join(","))] | join("|")' $< > $@

# Create directories
$(DIRS): ; mkdir -p $@

# Clean and install tasks
#
clean: ; rm -rf $(DIRS)

# requires Homebrew and pip out of the gate
install:
	which gdalinfo || brew install gdal
	pip list | grep svgis || pip install -U "svgis>=0.3.7,<1"
	which $(CONVERT) || brew install Caskroom/cask/xquartz imagemagick
	which jq || brew install jq

ready:
	-@ogr2ogr --version >/dev/null && echo GDAL ok || echo install GDAL
	-@which $(SVGIS) >/dev/null && echo $(SVGIS) ok || echo install $(SVGIS)
	-@$(CONVERT) --version >/dev/null && echo ImageMagick ok || echo install ImageMagick
	-@jq --version >/dev/null && echo jq ok || echo install jq
